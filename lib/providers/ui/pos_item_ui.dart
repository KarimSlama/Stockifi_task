import 'package:flutter/material.dart';

class POSItemUIProvider extends ChangeNotifier {
  final Map<String, bool> _expandedPOSItems = {};
  bool isPressed = true;

  String _itemsQueryString = '';
  String _posItemsQueryString = '';

  String get itemsQueryString => _itemsQueryString;
  String get posItemsQueryString => _posItemsQueryString;

  var pageStorageKey = const PageStorageKey<String>('0.0');

  void togglePOSItemExpanded(String posItemId, bool value) {
    if (_expandedPOSItems.containsKey(posItemId)) {
      _expandedPOSItems[posItemId] = value;
    } else {
      _expandedPOSItems.putIfAbsent(posItemId, () => value);
    }
    notifyListeners();
  }

  set itemsQueryString(String query) {
    _itemsQueryString = query;
    notifyListeners();
  }

  set posItemsQueryString(String query) {
    _posItemsQueryString = query;
    notifyListeners();
  }

  bool isPOSItemExpanded(String posItemId) {
    if (_expandedPOSItems.containsKey(posItemId)) {
      return _expandedPOSItems[posItemId]!;
    }
    return false;
  }

  void setIsPressed(bool value) {
    isPressed = value;
    notifyListeners();
  }

  void clearExpandedPOSItems() {
    _expandedPOSItems.clear();
    notifyListeners();
  }
}
