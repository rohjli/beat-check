# Tap Tempo Session Refactor Implementation Plan

> **For Claude:** REQUIRED SUB-SKILL: Use superpowers:executing-plans to implement this plan task-by-task.

**Goal:** Move tap tempo session logic into a pure-Dart domain engine and keep the Provider thin, while preserving and improving behavior (auto-reset after inactivity, ignored tap feedback).

**Architecture:** Introduce `TapTempoSession` in the domain layer to own timing state and return immutable `TapTempoResult`. The Provider delegates to the session and manages timers for inactivity/feedback. UI reads `TapTempoResult` and renders by state.

**Tech Stack:** Flutter, Dart, Provider, flutter_test.

### Task 1: Add Domain State + Result Entities

**Files:**
- Create: `lib/features/tap_tempo/domain/entities/tap_tempo_state.dart`
- Create: `lib/features/tap_tempo/domain/entities/tap_tempo_result.dart`
- Test: `test/features/tap_tempo/domain/entities/tap_tempo_state_test.dart`
- Test: `test/features/tap_tempo/domain/entities/tap_tempo_result_test.dart`

**Step 1: Write the failing tests**

```dart
// test/features/tap_tempo/domain/entities/tap_tempo_state_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';

void main() {
  test('TapTempoState exposes all states', () {
    expect(TapTempoState.idle, isNotNull);
    expect(TapTempoState.collecting, isNotNull);
    expect(TapTempoState.stable, isNotNull);
    expect(TapTempoState.ignored, isNotNull);
  });
}
```

```dart
// test/features/tap_tempo/domain/entities/tap_tempo_result_test.dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_result.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';

void main() {
  test('TapTempoResult carries state, bpm, tapCount, feedback', () {
    const result = TapTempoResult(
      state: TapTempoState.collecting,
      bpm: null,
      tapCount: 1,
      feedback: null,
    );
    expect(result.state, TapTempoState.collecting);
    expect(result.bpm, isNull);
    expect(result.tapCount, 1);
    expect(result.feedback, isNull);
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/tap_tempo/domain/entities/tap_tempo_state_test.dart`  
Expected: FAIL (missing files/classes).

**Step 3: Write minimal implementation**

```dart
// lib/features/tap_tempo/domain/entities/tap_tempo_state.dart
enum TapTempoState { idle, collecting, stable, ignored }
```

```dart
// lib/features/tap_tempo/domain/entities/tap_tempo_result.dart
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';

class TapTempoResult {
  final TapTempoState state;
  final double? bpm;
  final int tapCount;
  final String? feedback;

  const TapTempoResult({
    required this.state,
    required this.bpm,
    required this.tapCount,
    required this.feedback,
  });
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/tap_tempo/domain/entities/tap_tempo_state_test.dart test/features/tap_tempo/domain/entities/tap_tempo_result_test.dart`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/tap_tempo/domain/entities/tap_tempo_state.dart lib/features/tap_tempo/domain/entities/tap_tempo_result.dart test/features/tap_tempo/domain/entities/tap_tempo_state_test.dart test/features/tap_tempo/domain/entities/tap_tempo_result_test.dart
git commit -m "feat(tap-tempo): add domain tap tempo result types"
```

### Task 2: Add TapTempoSession Tests

**Files:**
- Create: `test/features/tap_tempo/domain/services/tap_tempo_session_test.dart`

**Step 1: Write the failing tests**

```dart
import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/core/constants/bpm_constants.dart';
import 'package:beat_check/features/tap_tempo/domain/services/tap_tempo_session.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';

void main() {
  group('TapTempoSession', () {
    test('first tap enters collecting', () {
      final session = TapTempoSession();
      final result = session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
      expect(result.state, TapTempoState.collecting);
      expect(result.tapCount, 1);
      expect(result.bpm, isNull);
    });

    test('second tap computes bpm and enters stable', () {
      final session = TapTempoSession();
      session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
      final result = session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0, 500));
      expect(result.state, TapTempoState.stable);
      expect(result.bpm, isNotNull);
    });

    test('too-fast tap returns ignored with feedback', () {
      final session = TapTempoSession();
      session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
      final result = session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0, 100));
      expect(result.state, TapTempoState.ignored);
      expect(result.feedback, isNotNull);
    });

    test('long pause resets session', () {
      final session = TapTempoSession();
      session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
      session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0, 500));
      final result = session.recordTapAt(
        DateTime(2026, 1, 1, 12, 0, 0, BpmConstants.resetThresholdMs + 100),
      );
      expect(result.tapCount, 1);
      expect(result.bpm, isNull);
    });
  });
}
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/tap_tempo/domain/services/tap_tempo_session_test.dart`  
Expected: FAIL (missing class).

### Task 3: Implement TapTempoSession

**Files:**
- Create: `lib/features/tap_tempo/domain/services/tap_tempo_session.dart`
- Modify: `lib/features/tap_tempo/domain/services/bpm_calculator.dart` (if needed for API alignment)

**Step 1: Write minimal implementation**

```dart
import 'package:beat_check/core/constants/bpm_constants.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_result.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';
import 'package:beat_check/features/tap_tempo/domain/services/bpm_calculator.dart';

class TapTempoSession {
  TapTempoSession({BpmCalculator? calculator})
      : _calculator = calculator ?? BpmCalculator();

  final BpmCalculator _calculator;
  final List<int> _intervals = [];
  DateTime? _lastTapTime;
  int _tapCount = 0;
  double? _bpm;

  TapTempoResult recordTapAt(DateTime tapTime) {
    if (_lastTapTime == null) {
      _lastTapTime = tapTime;
      _tapCount = 1;
      return _result(state: TapTempoState.collecting);
    }

    final interval = tapTime.difference(_lastTapTime!).inMilliseconds;
    _lastTapTime = tapTime;

    if (interval > BpmConstants.resetThresholdMs) {
      _resetInternal();
      _lastTapTime = tapTime;
      _tapCount = 1;
      return _result(state: TapTempoState.collecting);
    }

    if (interval < BpmConstants.minIntervalMs) {
      return _result(
        state: TapTempoState.ignored,
        feedback: 'Tap too fast',
      );
    }

    _intervals.add(interval);
    _tapCount++;

    while (_intervals.length > BpmConstants.windowSizeIntervals) {
      _intervals.removeAt(0);
    }

    _bpm = _calculator.calculateBpmWithFiltering(_intervals);
    return _result(state: TapTempoState.stable);
  }

  TapTempoResult reset() {
    _resetInternal();
    return _result(state: TapTempoState.idle);
  }

  TapTempoResult _result({required TapTempoState state, String? feedback}) {
    return TapTempoResult(
      state: state,
      bpm: _bpm,
      tapCount: _tapCount,
      feedback: feedback,
    );
  }

  void _resetInternal() {
    _intervals.clear();
    _tapCount = 0;
    _bpm = null;
    _lastTapTime = null;
  }
}
```

**Step 2: Run test to verify it passes**

Run: `flutter test test/features/tap_tempo/domain/services/tap_tempo_session_test.dart`  
Expected: PASS.

**Step 3: Commit**

```bash
git add lib/features/tap_tempo/domain/services/tap_tempo_session.dart test/features/tap_tempo/domain/services/tap_tempo_session_test.dart
git commit -m "feat(tap-tempo): add tap tempo session engine"
```

### Task 4: Update Provider to Use TapTempoSession + Timers

**Files:**
- Modify: `lib/features/tap_tempo/presentation/providers/tap_tempo_provider.dart`
- Modify: `test/features/tap_tempo/presentation/providers/tap_tempo_provider_test.dart`

**Step 1: Write failing tests (timer behavior)**

```dart
import 'package:fake_async/fake_async.dart';
// ...
test('inactivity timer auto-resets', () {
  fakeAsync((async) {
    provider.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
    async.elapse(const Duration(milliseconds: 2100));
    expect(provider.result.state, TapTempoState.idle);
  });
});
```

**Step 2: Run test to verify it fails**

Run: `flutter test test/features/tap_tempo/presentation/providers/tap_tempo_provider_test.dart`  
Expected: FAIL (missing result, timer behavior).

**Step 3: Write minimal implementation**

```dart
// tap_tempo_provider.dart (sketch)
class TapTempoProvider extends ChangeNotifier {
  TapTempoProvider({TapTempoSession? session})
      : _session = session ?? TapTempoSession(),
        _result = const TapTempoResult(
          state: TapTempoState.idle,
          bpm: null,
          tapCount: 0,
          feedback: null,
        );

  final TapTempoSession _session;
  TapTempoResult _result;
  Timer? _resetTimer;
  Timer? _feedbackTimer;

  TapTempoResult get result => _result;

  void recordTapAt(DateTime tapTime) {
    _result = _session.recordTapAt(tapTime);
    _scheduleAutoReset();
    _scheduleFeedbackClear();
    notifyListeners();
  }

  void reset() {
    _cancelTimers();
    _result = _session.reset();
    notifyListeners();
  }
}
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/tap_tempo/presentation/providers/tap_tempo_provider_test.dart`  
Expected: PASS.

**Step 5: Commit**

```bash
git add lib/features/tap_tempo/presentation/providers/tap_tempo_provider.dart test/features/tap_tempo/presentation/providers/tap_tempo_provider_test.dart
git commit -m "refactor(tap-tempo): make provider delegate to session"
```

### Task 5: Update UI to Read TapTempoResult

**Files:**
- Modify: `lib/features/tap_tempo/presentation/screens/tap_tempo_screen.dart`
- Modify: `test/features/tap_tempo/presentation/screens/tap_tempo_screen_test.dart`
- Remove: `lib/features/tap_tempo/presentation/providers/tap_tempo_state.dart`
- Modify: `test/features/tap_tempo/presentation/providers/tap_tempo_state_test.dart` (delete or move to domain)

**Step 1: Write failing test updates**

```dart
// Update imports in screen tests to use domain TapTempoState
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';
```

**Step 2: Run tests to verify they fail**

Run: `flutter test test/features/tap_tempo/presentation/screens/tap_tempo_screen_test.dart`  
Expected: FAIL (old state import/members).

**Step 3: Write minimal implementation**

```dart
// tap_tempo_screen.dart (sketch changes)
final result = context.watch<TapTempoProvider>().result;
switch (result.state) { ... }
```

**Step 4: Run tests to verify they pass**

Run: `flutter test test/features/tap_tempo/presentation/screens/tap_tempo_screen_test.dart test/features/tap_tempo/presentation/providers/tap_tempo_state_test.dart`  
Expected: PASS (or remove obsolete test).

**Step 5: Commit**

```bash
git add lib/features/tap_tempo/presentation/screens/tap_tempo_screen.dart test/features/tap_tempo/presentation/screens/tap_tempo_screen_test.dart test/features/tap_tempo/domain/entities/tap_tempo_state_test.dart
git rm lib/features/tap_tempo/presentation/providers/tap_tempo_state.dart test/features/tap_tempo/presentation/providers/tap_tempo_state_test.dart
git commit -m "refactor(tap-tempo): use domain result/state in UI"
```

### Task 6: Full Test Pass

**Step 1: Run all tests**

Run: `flutter test`  
Expected: PASS (all tests green).

**Step 2: Commit (if needed for fixes)**

```bash
git add <any remaining files>
git commit -m "test: fix tap tempo refactor tests"
```

