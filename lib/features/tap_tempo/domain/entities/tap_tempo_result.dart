import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';

class TapTempoResult {
  final TapTempoState state;
  final double? bpm;
  final int tapCount;
  final String? feedback;

  const TapTempoResult({
    required this.state,
    required this.bpm,
    required this.tapCount,
    required this.feedback,
  });
}
