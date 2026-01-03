import 'package:fake_async/fake_async.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/core/constants/bpm_constants.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_provider.dart';

void main() {
  group('TapTempoProvider', () {
    late TapTempoProvider provider;

    setUp(() {
      provider = TapTempoProvider();
    });

    group('initial state', () {
      test('result starts idle', () {
        expect(provider.result.state, TapTempoState.idle);
      });

      test('result bpm is null', () {
        expect(provider.result.bpm, isNull);
      });

      test('result tapCount is 0', () {
        expect(provider.result.tapCount, 0);
      });
    });

    group('recordTap', () {
      test('first tap transitions to collecting state', () {
        provider.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
        expect(provider.result.state, TapTempoState.collecting);
      });

      test('first tap sets tapCount to 1', () {
        provider.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
        expect(provider.result.tapCount, 1);
      });

      test('first tap does not calculate BPM yet', () {
        provider.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
        expect(provider.result.bpm, isNull);
      });

      test('second tap calculates BPM', () {
        final baseTime = DateTime(2026, 1, 1, 12, 0, 0);
        provider.recordTapAt(baseTime);
        provider.recordTapAt(
          baseTime.add(const Duration(milliseconds: 500)),
        );
        expect(provider.result.bpm, isNotNull);
      });

      test('second tap increments tapCount to 2', () {
        final baseTime = DateTime(2026, 1, 1, 12, 0, 0);
        provider.recordTapAt(baseTime);
        provider.recordTapAt(
          baseTime.add(const Duration(milliseconds: 500)),
        );
        expect(provider.result.tapCount, 2);
      });

      test('notifies listeners on tap', () {
        var notified = false;
        provider.addListener(() => notified = true);
        provider.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
        expect(notified, isTrue);
      });
    });

    group('auto-reset on long pause', () {
      test('resets after pause exceeding threshold', () {
        final baseTime = DateTime(2026, 1, 1, 12, 0, 0);
        provider.recordTapAt(baseTime);
        provider.recordTapAt(
          baseTime.add(const Duration(milliseconds: 500)),
        );
        expect(provider.result.tapCount, 2);

        provider.recordTapAt(
          baseTime.add(
            Duration(
              milliseconds: 500 + BpmConstants.resetThresholdMs + 1,
            ),
          ),
        );

        expect(provider.result.tapCount, 1);
        expect(provider.result.bpm, isNull);
      });
    });

    group('too-fast tap rejection', () {
      test('ignores taps faster than minIntervalMs', () {
        final baseTime = DateTime(2026, 1, 1, 12, 0, 0);
        provider.recordTapAt(baseTime);
        provider.recordTapAt(
          baseTime.add(const Duration(milliseconds: 100)),
        );

        expect(provider.result.state, TapTempoState.ignored);
        expect(provider.result.tapCount, 1);
        expect(provider.result.feedback, isNotNull);
      });
    });

    group('inactivity timer', () {
      test('auto-resets after threshold without taps', () {
        fakeAsync((async) {
          provider.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
          async.elapse(
            Duration(milliseconds: BpmConstants.resetThresholdMs + 1),
          );
          expect(provider.result.state, TapTempoState.idle);
          expect(provider.result.tapCount, 0);
        });
      });
    });

    group('ignored feedback clearing', () {
      test('returns to stable after feedback window', () {
        fakeAsync((async) {
          final baseTime = DateTime(2026, 1, 1, 12, 0, 0);
          provider.recordTapAt(baseTime);
          provider.recordTapAt(
            baseTime.add(const Duration(milliseconds: 500)),
          );
          expect(provider.result.state, TapTempoState.stable);

          provider.recordTapAt(
            baseTime.add(const Duration(milliseconds: 550)),
          );
          expect(provider.result.state, TapTempoState.ignored);

          async.elapse(const Duration(milliseconds: 200));
          expect(provider.result.state, TapTempoState.stable);
        });
      });
    });
  });
}
