import 'package:beat_check/core/constants/bpm_constants.dart';

class BpmCalculator {
  double? calculateBpm(List<int> intervals) {
    if (intervals.isEmpty) {
      return null;
    }

    double weightedSum = 0;
    double totalWeight = 0;

    for (int i = 0; i < intervals.length; i++) {
      final weight = (i + 1).toDouble();
      weightedSum += intervals[i] * weight;
      totalWeight += weight;
    }

    final weightedMeanMs = weightedSum / totalWeight;
    final bpm = 60000 / weightedMeanMs;

    return bpm.clamp(
      BpmConstants.minBpm.toDouble(),
      BpmConstants.maxBpm.toDouble(),
    );
  }

  List<int> filterOutliers(List<int> intervals) {
    if (intervals.isEmpty) {
      return [];
    }

    if (intervals.length == 1) {
      return intervals;
    }

    final sorted = List<int>.from(intervals)..sort();
    final middle = sorted.length ~/ 2;
    final median = sorted.length.isOdd
        ? sorted[middle].toDouble()
        : (sorted[middle - 1] + sorted[middle]) / 2;

    final threshold = median * BpmConstants.outlierThresholdPercent / 100;
    final minValid = median - threshold;
    final maxValid = median + threshold;

    final filtered = intervals
        .where((interval) => interval >= minValid && interval <= maxValid)
        .toList();

    return filtered.isEmpty ? intervals : filtered;
  }

  double? calculateBpmWithFiltering(List<int> intervals) {
    final filtered = filterOutliers(intervals);
    return calculateBpm(filtered);
  }
}
