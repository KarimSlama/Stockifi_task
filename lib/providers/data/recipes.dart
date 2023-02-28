// Flutter Packages
import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:fuzzy/data/result.dart';
import 'package:fuzzy/fuzzy.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/count_item.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../../models/recipe.dart';

// Services
import '../../services/recipe_service.dart';

// Utils
import '../../utils/logger_util.dart';

class RecipeProvider with ChangeNotifier {
  late RecipeService _recipeService;
  final List<PosItem> posItems;

  RecipeProvider({
    RecipeService? recipeService,
    AuthService? authService,
    this.posItems = const [],
  }) {
    _recipeService = recipeService ?? GetIt.instance<RecipeService>();
    _recipes = [...posItems.map((e) => Recipe.fromPOSItem(e)).toList()];
    _userId = (authService ?? GetIt.instance<AuthService>()).uid ?? '';
  }

  // States
  late String _userId;
  List<Recipe> _recipes = [];
  Fuzzy<Recipe> _fuse = Fuzzy([]);
  StreamSubscription<List<Recipe>>? _recipesStreamSub;
  bool _isLoading = true;
  bool _isInit = false;

  List<Recipe> _deletedRecipes = [];
  Fuzzy<Recipe> _deletedRecipesIncludedFuse = Fuzzy([]);
  StreamSubscription<List<Recipe>>? _deletedRecipesStreamSub;
  bool _isLoadingDeletedRecipes = true;
  bool _isDeletedRecipesInit = false;

  List<Recipe> _archivedRecipes = [];
  Fuzzy<Recipe> _archivedRecipesFuse = Fuzzy([]);
  StreamSubscription<List<Recipe>>? _archivedRecipesStreamSub;
  bool _isLoadingArchivedRecipes = true;
  bool _isArchivedRecipesInit = false;

  Set<String> itemsInRecipes = {};
  bool _showArchived = false;

  final _fuzzyOptions = FuzzyOptions(
    threshold: 0.4,
    location: 0,
    distance: 150,
    keys: [
      WeightedKey(
        name: 'name',
        getter: (Recipe x) => x.name ?? '',
        weight: 0.8,
      ),
      WeightedKey(
        name: 'items',
        getter: (Recipe x) {
          return (x.itemsV2).keys.toString();
        },
        weight: 0.5,
      ),
    ],
  );

  // Getters
  bool get showArchived => _showArchived;
  bool get isLoading => _isLoading;
  bool get isLoadingDeletedRecipes => _isLoadingDeletedRecipes;
  bool get isLoadingArchivedRecipes => _isLoadingArchivedRecipes;
  String get userId => _userId;

  final Map<String, List<String>> _types = {
    'Recipe': [
      'Prebatch',
      'Menu Item',
    ],
  };

  Map<String, List<String>> get types => _types;

  List<String> get allVarieties {
    var varieties = <String>[];

    for (var element in _types.values) {
      varieties.addAll(element);
    }

    return varieties;
  }

  List<Recipe> get recipes {
    _recipesStreamSub ?? _listenToRecipesStream();
    return [..._recipes];
  }

  List<Recipe> get prebatches {
    _recipesStreamSub ?? _listenToRecipesStream();
    return [..._recipes.where((element) => !element.isDish)];
  }

  List<Recipe> get menuItems {
    _recipesStreamSub ?? _listenToRecipesStream();
    return [..._recipes.where((element) => element.isDish)];
  }

  List<Recipe> getRecipesInclDeleted() {
    _recipesStreamSub ?? _listenToRecipesStream();
    _deletedRecipesStreamSub ?? _listenToDeletedItemsStream();
    return [..._recipes, ..._deletedRecipes];
  }

  List<Recipe> getArchivedRecipes() {
    _archivedRecipesStreamSub ?? _listenToArchivedItemsStream();
    return [..._archivedRecipes];
  }

  List<Recipe> getAllRecipes() {
    _recipesStreamSub ?? _listenToRecipesStream();
    _deletedRecipesStreamSub ?? _listenToDeletedItemsStream();
    _archivedRecipesStreamSub ?? _listenToArchivedItemsStream();
    return [..._recipes, ..._deletedRecipes, ..._archivedRecipes];
  }

  void toggleShowArchived() {
    _showArchived = !_showArchived;
    notifyListeners();
  }

  bool? isRecipeDeleted(String recipeId) {
    final recipe = getRecipesInclDeleted()
        .firstWhereOrNull((element) => element.id == recipeId);

    if (recipe == null) return null;
    return recipe.deleted;
  }

  Future<void>? cancelStreamSubscriptions() {
    return _recipesStreamSub?.cancel();
  }

  void _listenToRecipesStream() {
    _recipesStreamSub =
        _recipeService.getRecipesStream().listen((List<Recipe> recipes) {
      _recipes = recipes;

      _loadFuse();
      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  void _listenToDeletedItemsStream() {
    final deletedRecipesStream =
        _recipeService.getRecipesStream(isFetchingDeleted: true);
    _deletedRecipesStreamSub =
        deletedRecipesStream.listen((List<Recipe> recipes) {
      _deletedRecipes = recipes;

      _deletedRecipesIncludedFuse = Fuzzy(
        getRecipesInclDeleted().toList(),
        options: _fuzzyOptions,
      );

      if (!_isDeletedRecipesInit) {
        _isDeletedRecipesInit = true;
        _isLoadingDeletedRecipes = false;
      }
      notifyListeners();
    });
  }

  void _listenToArchivedItemsStream() {
    final archivedRecipesStream =
        _recipeService.getRecipesStream(isFetchingArchived: true);
    _archivedRecipesStreamSub =
        archivedRecipesStream.listen((List<Recipe> recipes) {
      _archivedRecipes = recipes;

      _archivedRecipesFuse = Fuzzy(
        _archivedRecipes,
        options: _fuzzyOptions,
      );

      if (!_isArchivedRecipesInit) {
        _isArchivedRecipesInit = true;
        _isLoadingArchivedRecipes = false;
      }
      notifyListeners();
    });
  }

  Future<String> createRecipe(Recipe recipe) async {
    try {
      await _recipeService.createRecipe(recipe);
      logger.i('RecipeProvider - createRecipe is successful');
      return 'Recipe created';
    } catch (error, stackTrace) {
      logger.e('RecipeProvider - createRecipe failed\n$error\n$stackTrace');

      SentryUtil.error('RecipeProvider.createRecipe() error: Recipe $recipe',
          'RecipeProvider class', error, stackTrace);

      return error.toString();
    }
  }

  Future<String> updateRecipe(Recipe recipe) async {
    try {
      await _recipeService.updateRecipe(recipe);
      logger.i(
          'debug RecipeProvider - updateRecipe is successful ${recipe.cost}');
      return 'Recipe updated';
    } catch (error, stackTrace) {
      logger.e('RecipeProvider - updateRecipe failed\n$error\n$stackTrace');

      SentryUtil.error('RecipeProvider.updateRecipe() error: Recipe $recipe',
          'RecipeProvider class', error, stackTrace);

      return error.toString();
    }
  }

  Future<String> softDeleteRecipe(String recipeId) async {
    try {
      await _recipeService.softDeleteRecipe(recipeId);

      logger.i('RecipeProvider - softDeleteRecipe is successful');
      return 'Recipe deleted';
    } catch (error, stackTrace) {
      logger.e('RecipeProvider - softDeleteRecipe failed\n$error\n$stackTrace');

      SentryUtil.error(
          'RecipeProvider.softDeleteRecipe() error: Recipe ID $recipeId',
          'RecipeProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }

  Future<String> archiveRecipe(String recipeId) async {
    try {
      await _recipeService.setArchived(recipeId, true);

      logger.i('RecipeProvider - archiveRecipe is successful');
      return 'Recipe deleted';
    } catch (error, stackTrace) {
      logger.e('RecipeProvider - archiveRecipe failed\n$error\n$stackTrace');

      SentryUtil.error(
          'RecipeProvider.archiveRecipe() error: Recipe ID $recipeId',
          'RecipeProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }

  Future<String> unarchiveRecipe(String recipeId) async {
    try {
      await _recipeService.setArchived(recipeId, false);

      logger.i('RecipeProvider - unarchiveRecipe is successful');
      return 'Recipe deleted';
    } catch (error, stackTrace) {
      logger.e('RecipeProvider - unarchiveRecipe failed\n$error\n$stackTrace');

      SentryUtil.error(
          'RecipeProvider.archiveRecipe() error: Recipe ID $recipeId',
          'RecipeProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }

  void _loadFuse() {
    _fuse = Fuzzy(
      _recipes,
      options: _fuzzyOptions,
    );
  }

  List<Recipe> searchRecipes(String query) {
    final results = _fuse.search(query);
    final recipes = [...results.map((e) => e.item).toList()];
    return [...recipes];
  }

  List<Recipe> searchPrebatches(
    String query, {
    bool isDeletedItemsIncluded = false,
    bool searchArchivedPrebatches = false,
  }) {
    List<Result<Recipe>> results = [];

    if (isDeletedItemsIncluded) {
      results = _deletedRecipesIncludedFuse.search(query);
    } else if (searchArchivedPrebatches) {
      results = _archivedRecipesFuse.search(query);
    } else {
      results = _fuse.search(query);
    }

    final recipes = [...results.map((e) => e.item).toList()];
    return [...recipes.where((element) => !element.isDish)];
  }

  List<Recipe> searchDishes(
    String query, {
    bool isDeletedItemsIncluded = false,
    bool searchArchivedDishes = false,
  }) {
    List<Result<Recipe>> results = [];

    if (isDeletedItemsIncluded) {
      results = _deletedRecipesIncludedFuse.search(query);
    } else if (searchArchivedDishes) {
      results = _archivedRecipesFuse.search(query);
    } else {
      results = _fuse.search(query);
    }

    final recipes = [...results.map((e) => e.item).toList()];
    return [...recipes.where((element) => element.isDish)];
  }

  Recipe? findById(
    String id, {
    bool deletedIncluded = true,
    bool archivedIncluded = true,
  }) {
    final recipe = [
      ..._recipes,
      if (archivedIncluded) ..._archivedRecipes,
      if (deletedIncluded) ..._deletedRecipes,
    ].firstWhereOrNull((element) => element.id == id);
    return recipe;
  }

  Recipe? findPrebatchById(String id) {
    final recipe =
        [..._recipes].firstWhereOrNull((e) => e.id == id && !e.isDish);
    return recipe;
  }

  Recipe? findDishById(String id) {
    final recipe =
        [..._recipes].firstWhereOrNull((e) => (e.id == id) && e.isDish);
    return recipe;
  }

  ///filterRecipesById() is a more optimized version of findById(). Instead of iterating through all available items
  /// for every countitems, here we are filtering first the only items necessary for the iteration for every countitem.
  /// This significantly reduces time, which previously thought to be causing infinit loop of 'findbyid is successful null'

  List<Recipe>? filterRecipesById(List<CountItem> listOfCountItems) {
    final recipes = [..._recipes]
        .where((recipe) => listOfCountItems.any((e) => e.itemId == recipe.id))
        .toList();
    return recipes;
  }

  bool isItemOrRecipeInAnyRecipe(String itemId) {
    var value = false;

    for (var recipe in _recipes) {
      value = (recipe.itemsV2).containsKey(itemId);
      if (value) {
        itemsInRecipes.add(recipe.id!);
      }
    }
    for (var recipe in _recipes) {
      value = (recipe.itemsV2).containsKey(itemId);
      if (value == true) break;
    }

    return value;
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}
