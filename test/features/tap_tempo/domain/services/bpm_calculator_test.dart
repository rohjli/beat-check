import 'package:flutter_test/flutter_test.dart';
import 'package:beat_check/features/tap_tempo/domain/services/bpm_calculator.dart';

void main() {
  group('BpmCalculator', () {
    late BpmCalculator calculator;

    setUp(() {
      calculator = BpmCalculator();
    });

    group('calculateBpm', () {
      test('returns null for empty intervals', () {
        expect(calculator.calculateBpm([]), isNull);
      });

      test('calculates BPM from single interval', () {
        final bpm = calculator.calculateBpm([500]);
        expect(bpm, closeTo(120.0, 0.1));
      });

      test('calculates BPM from uniform intervals', () {
        final bpm = calculator.calculateBpm([500, 500, 500, 500]);
        expect(bpm, closeTo(120.0, 0.1));
      });

      test('applies weighted average favoring recent intervals', () {
        final bpm = calculator.calculateBpm([600, 600, 500, 500]);
        expect(bpm, greaterThan(108.0));
      });

      test('clamps BPM to minimum', () {
        final bpm = calculator.calculateBpm([3000]);
        expect(bpm, 30.0);
      });

      test('clamps BPM to maximum', () {
        final bpm = calculator.calculateBpm([150]);
        expect(bpm, 300.0);
      });
    });

    group('filterOutliers', () {
      test('returns empty list for empty input', () {
        expect(calculator.filterOutliers([]), isEmpty);
      });

      test('keeps all intervals within 25% of median', () {
        final filtered = calculator.filterOutliers([400, 500, 600]);
        expect(filtered, [400, 500, 600]);
      });

      test('removes outliers beyond 25% of median', () {
        final filtered = calculator.filterOutliers([500, 500, 500, 1000]);
        expect(filtered, [500, 500, 500]);
      });

      test('returns original list if all values are outliers', () {
        final filtered = calculator.filterOutliers([100, 1000]);
        expect(filtered, [100, 1000]);
      });

      test('handles single interval', () {
        final filtered = calculator.filterOutliers([500]);
        expect(filtered, [500]);
      });
    });

    group('calculateBpm with outlier filtering', () {
      test('filters outliers before calculating BPM', () {
        final bpm = calculator.calculateBpmWithFiltering([500, 500, 500, 2000]);
        expect(bpm, closeTo(120.0, 1.0));
      });
    });
  });
}
