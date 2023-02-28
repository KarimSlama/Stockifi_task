import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///This provider will enable the hiding and showing
/// of Count Item Search FloatingActionButton

class CountItemSearchFabUIProvider with ChangeNotifier {
  bool _isSearchFabEnabled = true;

  bool get isSearchFabEnabled => _isSearchFabEnabled;

  void setIsSearchFabEnabled(bool value) {
    _isSearchFabEnabled = value;
    notifyListeners();
  }
}
