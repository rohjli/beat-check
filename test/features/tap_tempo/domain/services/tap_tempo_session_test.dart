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
      final result = session.recordTapAt(
        DateTime(2026, 1, 1, 12, 0, 0, 500),
      );
      expect(result.state, TapTempoState.stable);
      expect(result.bpm, isNotNull);
    });

    test('too-fast tap returns ignored with feedback', () {
      final session = TapTempoSession();
      session.recordTapAt(DateTime(2026, 1, 1, 12, 0, 0));
      final result = session.recordTapAt(
        DateTime(2026, 1, 1, 12, 0, 0, 100),
      );
      expect(result.state, TapTempoState.ignored);
      expect(result.feedback, isNotNull);
    });

    test('long pause resets session', () {
      final session = TapTempoSession();
      final baseTime = DateTime(2026, 1, 1, 12, 0, 0);
      session.recordTapAt(baseTime);
      session.recordTapAt(baseTime.add(const Duration(milliseconds: 500)));
      final result = session.recordTapAt(
        baseTime.add(
          Duration(
            milliseconds: 500 + BpmConstants.resetThresholdMs + 1,
          ),
        ),
      );
      expect(result.tapCount, 1);
      expect(result.bpm, isNull);
    });
  });
}
