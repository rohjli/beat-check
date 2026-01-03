import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/core/constants/bpm_constants.dart';

void main() {
  group('BpmConstants', () {
    test('minBpm is 30', () {
      expect(BpmConstants.minBpm, 30);
    });

    test('maxBpm is 300', () {
      expect(BpmConstants.maxBpm, 300);
    });

    test('windowSizeIntervals is 8', () {
      expect(BpmConstants.windowSizeIntervals, 8);
    });

    test('resetThresholdMs is 2000', () {
      expect(BpmConstants.resetThresholdMs, 2000);
    });

    test('minIntervalMs is calculated from maxBpm', () {
      expect(BpmConstants.minIntervalMs, 200);
    });

    test('outlierThresholdPercent is 25', () {
      expect(BpmConstants.outlierThresholdPercent, 25);
    });
  });
}
