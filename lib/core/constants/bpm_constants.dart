class BpmConstants {
  BpmConstants._();

  static const int minBpm = 30;
  static const int maxBpm = 300;
  static const int windowSizeIntervals = 8;
  static const int resetThresholdMs = 2000;
  static const int minIntervalMs = 60000 ~/ maxBpm;
  static const int outlierThresholdPercent = 25;
}
