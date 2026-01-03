import 'package:flutter/foundation.dart';
import 'package:beat_check/core/constants/bpm_constants.dart';
import 'package:beat_check/features/tap_tempo/domain/services/bpm_calculator.dart';
import 'package:beat_check/features/tap_tempo/presentation/providers/tap_tempo_state.dart';

class TapTempoProvider extends ChangeNotifier {
  final BpmCalculator _calculator;

  TapTempoProvider({BpmCalculator? calculator})
    : _calculator = calculator ?? BpmCalculator();

  TapTempoScreenState _screenState = TapTempoScreenState.idle;
  double? _bpm;
  int _tapCount = 0;
  DateTime? _lastTapTime;
  final List<int> _intervals = [];

  TapTempoScreenState get screenState => _screenState;
  double? get bpm => _bpm;
  int get tapCount => _tapCount;

  void recordTap() {
    recordTapAt(DateTime.now());
  }

  void recordTapAt(DateTime tapTime) {
    if (_lastTapTime == null) {
      _lastTapTime = tapTime;
      _tapCount = 1;
      _screenState = TapTempoScreenState.collecting;
      notifyListeners();
      return;
    }

    final interval = tapTime.difference(_lastTapTime!).inMilliseconds;
    _lastTapTime = tapTime;

    if (interval > BpmConstants.resetThresholdMs) {
      _reset();
      _lastTapTime = tapTime;
      _tapCount = 1;
      _screenState = TapTempoScreenState.collecting;
      notifyListeners();
      return;
    }

    if (interval < BpmConstants.minIntervalMs) {
      _screenState = TapTempoScreenState.ignoredInput;
      notifyListeners();
      Future.delayed(const Duration(milliseconds: 200), () {
        if (_screenState == TapTempoScreenState.ignoredInput) {
          _screenState = _bpm != null
              ? TapTempoScreenState.stable
              : TapTempoScreenState.collecting;
          notifyListeners();
        }
      });
      return;
    }

    _intervals.add(interval);
    _tapCount++;

    while (_intervals.length > BpmConstants.windowSizeIntervals) {
      _intervals.removeAt(0);
    }

    _bpm = _calculator.calculateBpmWithFiltering(_intervals);
    _screenState = TapTempoScreenState.stable;
    notifyListeners();
  }

  void reset() {
    _reset();
    notifyListeners();
  }

  void _reset() {
    _screenState = TapTempoScreenState.idle;
    _bpm = null;
    _tapCount = 0;
    _lastTapTime = null;
    _intervals.clear();
  }
}
