import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/base_item.dart';

class WastageUIProvider extends ChangeNotifier {
  bool _isPressed = false;

  bool get isPressed => _isPressed;

  final Map<String, bool> _expandedWastages = {};

  bool _isPerKilo = false;
  bool get isPerKilo => _isPerKilo;

  BaseItem? _originalSelectedItem;
  BaseItem? get originalSelectedItem => _originalSelectedItem;

  var _pageStorageKey = const PageStorageKey<String>('0.0');

  PageStorageKey<String> getPageStorageKey() {
    return _pageStorageKey;
  }

  String queryString = '';

  void toggleWastageExpanded(String wastageId, bool value) {
    if (_expandedWastages.containsKey(wastageId)) {
      _expandedWastages[wastageId] = value;
    } else {
      _expandedWastages.putIfAbsent(wastageId, () => value);
    }
    notifyListeners();
  }

  void setPageStorageKey(double key) {
    _pageStorageKey = PageStorageKey<String>('$key');
  }

  bool isWastageExpanded(String wastageId) {
    if (_expandedWastages.containsKey(wastageId)) {
      return _expandedWastages[wastageId]!;
    }
    return false;
  }

  void setIsPressed(bool _) {
    _isPressed = _;
    notifyListeners();
  }

  void setIsPerKilo(bool _) {
    _isPerKilo = _;
    notifyListeners();
  }

  void setOriginalSelectedItem(BaseItem? _) {
    _originalSelectedItem = _;
  }

  void clearExpandedWastages() {
    _expandedWastages.clear();
    notifyListeners();
  }

  search(String query) {}
}
