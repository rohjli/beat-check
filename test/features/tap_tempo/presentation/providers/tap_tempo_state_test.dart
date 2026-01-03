import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_state.dart';

void main() {
  group('TapTempoScreenState', () {
    test('has idle state', () {
      expect(TapTempoScreenState.idle, isNotNull);
    });

    test('has collecting state', () {
      expect(TapTempoScreenState.collecting, isNotNull);
    });

    test('has stable state', () {
      expect(TapTempoScreenState.stable, isNotNull);
    });

    test('has ignoredInput state', () {
      expect(TapTempoScreenState.ignoredInput, isNotNull);
    });
  });
}
