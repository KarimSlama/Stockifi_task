import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/recipe.dart';

class EditRecipeUIState {}

class EditRecipeUIProvider with ChangeNotifier {
  Recipe recipe = Recipe();
  final _units = ['ml', 'g', 'pcs'];

  ///TODO: double check to see if deleting this variable does not affect anything
  ///this has to go away as all variable check is in [_recipe] already
  final _ingredients = <String, dynamic>{};
  final _itemsV2 = <String, num>{};
  String? _name = '';
  String? _note = '';
  String? _size = '';
  String? _selectedUnit;
  String? _ingredientQuery = '';

  void resetRecipe() {
    _ingredients.clear();
    _itemsV2.clear();
    _name = '';
    _note = '';
    _size = '';
    _selectedUnit = null;
    _ingredientQuery = '';
    recipe = Recipe();
    notifyListeners();
  }

  List<String> get units => [..._units];
  Map<String, dynamic> get ingredients => {..._ingredients};
  Map<String, num> get itemsV2 => {..._itemsV2};

  String get ingredientQuery => _ingredientQuery!;
  String? get name => _name;
  String? get note => _note;
  String? get size => _size;
  String? get selectedUnit => _selectedUnit;

  set name(String? value) {
    recipe = recipe.copyWith(name: value);
    _name = value;
    notifyListeners();
  }

  set note(String? value) {
    recipe = recipe.copyWith(note: value);
    _note = value;
    notifyListeners();
  }

  set size(String? value) {
    if (value != null && value.isNotEmpty) {
      recipe = recipe.copyWith(size: int.parse(value));
    } else {
      _size = '';
    }
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
