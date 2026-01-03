import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_provider.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_state.dart';

void main() {
  group('TapTempoProvider', () {
    late TapTempoProvider provider;

    setUp(() {
      provider = TapTempoProvider();
    });

    group('initial state', () {
      test('screenState is idle', () {
        expect(provider.screenState, TapTempoScreenState.idle);
      });

      test('bpm is null', () {
        expect(provider.bpm, isNull);
      });

      test('tapCount is 0', () {
        expect(provider.tapCount, 0);
      });
    });

    group('recordTap', () {
      test('first tap transitions to collecting state', () {
        provider.recordTap();
        expect(provider.screenState, TapTempoScreenState.collecting);
      });

      test('first tap sets tapCount to 1', () {
        provider.recordTap();
        expect(provider.tapCount, 1);
      });

      test('first tap does not calculate BPM yet', () {
        provider.recordTap();
        expect(provider.bpm, isNull);
      });

      test('second tap calculates BPM', () {
        provider.recordTap();
        provider.recordTapAt(
          DateTime.now().add(const Duration(milliseconds: 500)),
        );
        expect(provider.bpm, isNotNull);
      });

      test('second tap increments tapCount to 2', () {
        provider.recordTap();
        provider.recordTapAt(
          DateTime.now().add(const Duration(milliseconds: 500)),
        );
        expect(provider.tapCount, 2);
      });

      test('notifies listeners on tap', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.recordTap();
        expect(notified, isTrue);
      });
    });

    group('reset', () {
      test('resets to idle state', () {
        provider.recordTap();
        provider.reset();
        expect(provider.screenState, TapTempoScreenState.idle);
      });

      test('clears bpm', () {
        provider.recordTap();
        provider.recordTapAt(
          DateTime.now().add(const Duration(milliseconds: 500)),
        );
        provider.reset();
        expect(provider.bpm, isNull);
      });

      test('clears tapCount', () {
        provider.recordTap();
        provider.reset();
        expect(provider.tapCount, 0);
      });

      test('notifies listeners on reset', () {
        provider.recordTap();
        var notified = false;
        provider.addListener(() => notified = true);
        provider.reset();
        expect(notified, isTrue);
      });
    });

    group('auto-reset on long pause', () {
      test('resets after pause exceeding threshold', () {
        provider.recordTap();
        provider.recordTapAt(
          DateTime.now().add(const Duration(milliseconds: 500)),
        );
        expect(provider.tapCount, 2);

        provider.recordTapAt(
          DateTime.now().add(const Duration(milliseconds: 3500)),
        );

        expect(provider.tapCount, 1);
        expect(provider.bpm, isNull);
      });
    });

    group('too-fast tap rejection', () {
      test('ignores taps faster than minIntervalMs', () {
        provider.recordTap();
        provider.recordTapAt(
          DateTime.now().add(const Duration(milliseconds: 100)),
        );

        expect(provider.screenState, TapTempoScreenState.ignoredInput);
        expect(provider.tapCount, 1);
      });
    });

    group('window size limiting', () {
      test('keeps only last 8 intervals', () {
        final baseTime = DateTime.now();
        provider.recordTapAt(baseTime);

        for (var i = 1; i <= 10; i++) {
          provider.recordTapAt(baseTime.add(Duration(milliseconds: 500 * i)));
        }

        expect(provider.tapCount, 11);
        expect(provider.bpm, isNotNull);
      });
    });
  });
}
