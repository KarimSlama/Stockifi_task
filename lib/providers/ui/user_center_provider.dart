import 'package:flutter/material.dart';

class UserCenterProvider extends ChangeNotifier {
  bool _isVisible = false;

  bool get isVisible => _isVisible;

  void toggleUserCenter() {
    _isVisible = !_isVisible;
    notifyListeners();
  }

  void hideUserCenter() {
    _isVisible = false;
    notifyListeners();
  }

  void showUserCenter() {
    _isVisible = true;
    notifyListeners();
  }
}
