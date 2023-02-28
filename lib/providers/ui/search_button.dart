import 'package:flutter/material.dart';

class SearchButtonProvider with ChangeNotifier {
  bool _isSearchButtonExtended = true;

  bool get isSearchButtonExtended => _isSearchButtonExtended;

  set isSearchButtonExtended(bool isExtended) {
    if (_isSearchButtonExtended != isExtended) {
      _isSearchButtonExtended = isExtended;
      notifyListeners();
    }
  }
}
