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
