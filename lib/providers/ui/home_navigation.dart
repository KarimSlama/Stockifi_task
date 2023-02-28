import 'package:flutter/material.dart';

class HomeNavigationProvider with ChangeNotifier {
  bool _isNavRailExtended = false;

  bool get isNavRailExtended => _isNavRailExtended;

  set isNavRailExtended(bool value) {
    isNavRailExtended = value;
    notifyListeners();
  }

  void toggleNavRail() {
    _isNavRailExtended = !_isNavRailExtended;
    notifyListeners();
  }
}
