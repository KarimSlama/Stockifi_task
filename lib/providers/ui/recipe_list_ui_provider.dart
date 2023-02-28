import 'package:flutter/material.dart';

class RecipeListUIProvider extends ChangeNotifier {
  int _recipeListIndex = 0;

  int get recipeListIndex => _recipeListIndex;

  void setRecipeListIndex(int _) {
    _recipeListIndex = _;
    notifyListeners();
  }
}
