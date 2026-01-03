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
