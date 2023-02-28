import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/recipe.dart';

class DishesUIProvider with ChangeNotifier {
  Recipe recipe = Recipe();

  // Create Dish Page
  void resetRecipe() {
    _ingredients.clear();
    _itemsV2.clear();
    _name = '';
    _size = '1';
    _selectedUnit = 'pcs';
    ingredientQuery = '';
    recipe = Recipe();
    notifyListeners();
  }

  final _units = ['ml', 'g', 'pcs'];
  final _ingredients = <String, dynamic>{};
  final _itemsV2 = <String, num>{};
  String? _name = '';
  String? _size = '1';
  String? _selectedUnit = 'pcs';
  String? _ingredientQuery = '';

  List<String> get units => [..._units];
  Map<String, dynamic> get ingredients => {..._ingredients};
  Map<String, num> get itemsV2 => {..._itemsV2};
  String? get name => _name;
  String? get size => _size;
  String? get selectedUnit => _selectedUnit;
  String get ingredientQuery => _ingredientQuery!;

  set name(String? value) {
    recipe = recipe.copyWith(name: value);
    _name = value;
    notifyListeners();
  }

  set size(String? value) {
    recipe = recipe.copyWith(size: int.parse(value!));
    _size = value;
    notifyListeners();
  }

  set selectedUnit(String? value) {
    recipe = recipe.copyWith(unit: value);
    _selectedUnit = value;
    notifyListeners();
  }

  set ingredientQuery(String query) {
    _ingredientQuery = query;
    notifyListeners();
  }

  void putIngredient(String id) {
    _ingredients.putIfAbsent(id, () => 0);

    var itemsV2 = {...recipe.itemsV2};
    itemsV2.putIfAbsent(id, () => 0);
    recipe = recipe.copyWith(itemsV2: itemsV2);
    var sortedItemIds = [...recipe.sortedItemIds];
    sortedItemIds.add(id);
    recipe = recipe.copyWith(sortedItemIds: sortedItemIds);

    notifyListeners();
  }

  void removeIngredient(String id) {
    _ingredients.removeWhere(((key, value) => key == id));

    var itemsV2 = {...recipe.itemsV2};
    itemsV2.removeWhere((key, value) => key == id);
    recipe = recipe.copyWith(itemsV2: itemsV2);
    var sortedItemIds = [...recipe.sortedItemIds];
    sortedItemIds.removeWhere((element) => element == id);
    recipe = recipe.copyWith(sortedItemIds: sortedItemIds);

    notifyListeners();
  }

  void updateIngredientSize(String id, double size) {
    _ingredients[id] = size;
    var itemsV2 = {...recipe.itemsV2};
    itemsV2[id] = size;
    recipe = recipe.copyWith(itemsV2: itemsV2);
  }
}
