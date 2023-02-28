import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/enums.dart';

class RecipeUIProvider extends ChangeNotifier {
  String queryString = '';
  bool _isPressed = false;

  bool get isPressed => _isPressed;

  final Map<String, bool> _expandedRecipes = {};

  var _prebatchPageStorageKey =
      const PageStorageKey<String>('prebatchScrollController');
  var _dishesPageStorageKey =
      const PageStorageKey<String>('dishesScrollController');

  PageStorageKey<String> getPageStorageKey({
    RecipeType recipeType = RecipeType.prebatch,
  }) {
    switch (recipeType) {
      case RecipeType.prebatch:
        return _prebatchPageStorageKey;
      case RecipeType.dish:
        return _dishesPageStorageKey;

      default:
        return _prebatchPageStorageKey;
    }
  }

  void toggleRecipeExpanded(String recipeId, bool value) {
    if (_expandedRecipes.containsKey(recipeId)) {
      _expandedRecipes[recipeId] = value;
    } else {
      _expandedRecipes.putIfAbsent(recipeId, () => value);
    }
    notifyListeners();
  }

  void setPageStorageKey(
    double key, {
    RecipeType recipeType = RecipeType.prebatch,
  }) {
    switch (recipeType) {
      case RecipeType.prebatch:
        _prebatchPageStorageKey = PageStorageKey<String>('$key');
        break;
      case RecipeType.dish:
        _dishesPageStorageKey = PageStorageKey<String>('$key');
        break;

      default:
    }
  }

  bool isRecipeExpanded(String recipeId) {
    if (_expandedRecipes.containsKey(recipeId)) {
      return _expandedRecipes[recipeId]!;
    }
    return false;
  }

  void setIsPressed(bool _) {
    _isPressed = _;
    notifyListeners();
  }

  void clearExpandedRecipes() {
    _expandedRecipes.clear();
    notifyListeners();
  }
}
