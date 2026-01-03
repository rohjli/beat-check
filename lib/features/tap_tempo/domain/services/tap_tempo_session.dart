import 'package:beat_check/core/constants/bpm_constants.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_result.dart';
import 'package:beat_check/features/tap_tempo/domain/entities/tap_tempo_state.dart';
import 'package:beat_check/features/tap_tempo/domain/services/bpm_calculator.dart';

class TapTempoSession {
  TapTempoSession({BpmCalculator? calculator})
    : _calculator = calculator ?? BpmCalculator();

  final BpmCalculator _calculator;
  final List<int> _intervals = [];
  DateTime? _lastTapTime;
  int _tapCount = 0;
  double? _bpm;

  TapTempoResult recordTapAt(DateTime tapTime) {
    if (_lastTapTime == null) {
      _lastTapTime = tapTime;
      _tapCount = 1;
      return _result(state: TapTempoState.collecting);
    }

    final interval = tapTime.difference(_lastTapTime!).inMilliseconds;
    _lastTapTime = tapTime;

    if (interval > BpmConstants.resetThresholdMs) {
      _resetInternal();
      _lastTapTime = tapTime;
      _tapCount = 1;
      return _result(state: TapTempoState.collecting);
    }

    if (interval < BpmConstants.minIntervalMs) {
      return _result(
        state: TapTempoState.ignored,
        feedback: 'Tap too fast',
      );
    }

    _intervals.add(interval);
    _tapCount++;

    while (_intervals.length > BpmConstants.windowSizeIntervals) {
      _intervals.removeAt(0);
    }

    _bpm = _calculator.calculateBpmWithFiltering(_intervals);
    return _result(state: TapTempoState.stable);
  }

  TapTempoResult reset() {
    _resetInternal();
    return _result(state: TapTempoState.idle);
  }

  TapTempoResult _result({required TapTempoState state, String? feedback}) {
    return TapTempoResult(
      state: state,
      bpm: _bpm,
      tapCount: _tapCount,
      feedback: feedback,
    );
  }

  void _resetInternal() {
    _intervals.clear();
    _tapCount = 0;
    _bpm = null;
    _lastTapTime = null;
  }
}
