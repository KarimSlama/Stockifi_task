import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/count_item_helper.dart';

class ExistingCountUIProvider with ChangeNotifier {
  bool _isNewCountItem = false;
  bool _isVisibleSearchBar = false;
  bool _isUserInput = false;

  Set<CountItemHelper> _setOfCountItem = {};

  bool get isNewCountItem => _isNewCountItem;
  bool get isVisibleSearchBar => _isVisibleSearchBar;
  bool get isUserInput => _isUserInput;
  Set<CountItemHelper> get setOfCountItem => _setOfCountItem;

  void setIsNewCountItem(bool _) {
    _isNewCountItem = _;
    notifyListeners();
  }

  void setIsvisibleSearchBar(bool _) {
    _isVisibleSearchBar = _;
    notifyListeners();
  }

  void setIsUserInput(bool _) {
    _isUserInput = _;
  }

  void setSetOfCountItem(Set<CountItemHelper> _) {
    _setOfCountItem = _;
  }
}
