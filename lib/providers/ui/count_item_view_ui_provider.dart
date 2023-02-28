import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/base_item.dart';
import 'package:stocklio_flutter/models/count_item.dart';

///This provider will set the value of textToDisplay used in CalculationScreen Widget
///when a certain count item is selscted
class CountItemViewUIProvider with ChangeNotifier {
  String _textToDisplayWithCalc = '';
  String _textToDisplay = '';
  bool _isLoading = false;
  bool _isPerKilo = false;
  BaseItem? _selectedItem;
  CountItem? _selectedCountItem;
  final List<String> _itemsTypeFilters = [];
  final List<String> _itemsVarietyFilters = [];

  String get textToDisplayWithCalc => _textToDisplayWithCalc;
  String get textToDisplay => _textToDisplay;
  bool get isLoading => _isLoading;
  bool get isPerKilo => _isPerKilo;
  BaseItem? get selectedItem => _selectedItem;
  CountItem? get selectedCountItem => _selectedCountItem;
  List<String> get itemsTypeFilters => [..._itemsTypeFilters];
  List<String> get itemsVarietyFilters => [..._itemsVarietyFilters];

  void setTextToDisplayWithCalc(String _) {
    _textToDisplayWithCalc = _;
    notifyListeners();
  }

  void setTextToDisplay(String _) {
    _textToDisplay = _;
    notifyListeners();
  }

  void appendTextToDisplay(String _) {
    _textToDisplay += _;
    notifyListeners();
  }

  void setIsLoading(bool _) {
    _isLoading = _;
    notifyListeners();
  }

  void setIsPerKilo(bool _) {
    _isPerKilo = _;
    notifyListeners();
  }

  void setSelectedItem(BaseItem? _) {
    _selectedItem = _;
  }

  void setSelectedCountItem(CountItem? _) {
    _selectedCountItem = _;
  }

  void toggleItemsTypeFilter(String value) {
    final index = _itemsTypeFilters.indexWhere((element) => element == value);

    if (index == -1) {
      _itemsTypeFilters.add(value);
    } else {
      _itemsTypeFilters.removeAt(index);
    }
    notifyListeners();
  }

  void clearItemsTypeFilters() {
    _itemsTypeFilters.clear();
    notifyListeners();
  }

  void toggleItemsVarietyFilter(String value) {
    final index =
        _itemsVarietyFilters.indexWhere((element) => element == value);

    if (index == -1) {
      _itemsVarietyFilters.add(value);
    } else {
      _itemsVarietyFilters.removeAt(index);
    }
    notifyListeners();
  }

  void clearItemsVarietyFilters() {
    _itemsVarietyFilters.clear();
    notifyListeners();
  }
}
