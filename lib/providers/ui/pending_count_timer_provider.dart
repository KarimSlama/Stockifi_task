import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class PendingCountTimerProvider with ChangeNotifier {
  String _startedCountTime = '';
  String _endedCountTime = '';
  String get startedCountTime => _startedCountTime;
  String get endedCountTime => _endedCountTime;

  void setStartedCountTime(String _) {
    _startedCountTime = _;
    notifyListeners();
  }

  void setEndedCountTime(String _) async {
    _endedCountTime = _;
    notifyListeners();
  }

  void resetStartEndedCountTime() {
    _startedCountTime = '';
    _endedCountTime = '';
    notifyListeners();
  }
}
