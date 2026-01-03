import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:beat_check/core/constants/bpm_constants.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_result.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';
import 'package:beat_check/features/tap_tempo/domain/services/tap_tempo_session.dart';

class TapTempoProvider extends ChangeNotifier {
  TapTempoProvider({TapTempoSession? session})
    : _session = session ?? TapTempoSession(),
      _result = _idleResult;

  static const TapTempoResult _idleResult = TapTempoResult(
    state: TapTempoState.idle,
    bpm: null,
    tapCount: 0,
    feedback: null,
  );

  final TapTempoSession _session;
  TapTempoResult _result;
  TapTempoResult _lastNonIgnoredResult = _idleResult;
  Timer? _resetTimer;
  Timer? _feedbackTimer;

  TapTempoResult get result => _result;

  void recordTap() {
    recordTapAt(DateTime.now());
  }

  void recordTapAt(DateTime tapTime) {
    _result = _session.recordTapAt(tapTime);
    if (_result.state != TapTempoState.ignored) {
      _lastNonIgnoredResult = _result;
    }
    _scheduleAutoReset();
    _scheduleFeedbackClear();
    notifyListeners();
  }

  void reset() {
    _cancelTimers();
    _result = _session.reset();
    _lastNonIgnoredResult = _result;
    notifyListeners();
  }

  @override
  void dispose() {
    _cancelTimers();
    super.dispose();
  }

  void _scheduleAutoReset() {
    _resetTimer?.cancel();
    if (_result.tapCount == 0) {
      return;
    }
    _resetTimer = Timer(
      const Duration(milliseconds: BpmConstants.resetThresholdMs),
      () {
        _result = _session.reset();
        _lastNonIgnoredResult = _result;
        notifyListeners();
      },
    );
  }

  void _scheduleFeedbackClear() {
    _feedbackTimer?.cancel();
    if (_result.state != TapTempoState.ignored) {
      return;
    }

    _feedbackTimer = Timer(const Duration(milliseconds: 200), () {
      if (_result.state == TapTempoState.ignored) {
        _result = TapTempoResult(
          state: _lastNonIgnoredResult.state,
          bpm: _lastNonIgnoredResult.bpm,
          tapCount: _lastNonIgnoredResult.tapCount,
          feedback: null,
        );
        notifyListeners();
      }
    });
  }

  void _cancelTimers() {
    _resetTimer?.cancel();
    _feedbackTimer?.cancel();
  }
}
