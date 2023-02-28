import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

class ConfettiProvider with ChangeNotifier {
  bool _isConfettiSet = false;
  bool get isConfettiSet => _isConfettiSet;

  void setConfettiValue(bool _) {
    _isConfettiSet = _;
    notifyListeners();
  }
}
