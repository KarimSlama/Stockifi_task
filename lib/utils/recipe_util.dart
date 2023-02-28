import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/recipe.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';

import '../models/item.dart';

class RecipeUtil {
  static double getRecipeCost(
    BuildContext context,
    Recipe recipe,
  ) {
    final items = recipe.itemsV2;
    var tempCost = 0.0;

    items.forEach((key, value) {
      var item = context.read<ItemProvider>().findById(key);

      if (item == null) {
        final recipe = context.read<RecipeProvider>().findById(key);
        if (recipe == null) return;
        item = Item.fromRecipe(context, recipe);
      }

      final itemCost = item.cost;
      final recipeItemSize = ParseUtil.toNum(value);
      tempCost += recipeItemSize * itemCost;
    });

    // print('debug ${recipe.id} tempCost $tempCost');

    return tempCost;
  }

  static num getTotalCostByIngredients(
      BuildContext context, Map<String, dynamic> ingredients,
      {bool isSaved = false}) {
    var total = 0.0;

    ingredients.forEach((key, value) {
      var item = context.read<ItemProvider>().findById(key);

      if (item == null) {
        var recipe = context.read<RecipeProvider>().findById(key);
        if (recipe != null) {
          item ??= Item.fromRecipe(context, recipe);
        }
      }
      //NOTE: isSaved is used to make sure that we don't save the ingredientCost that's saved in DB
      final isItemCutawayEnabled =
          context.read<ProfileProvider>().profile.isItemCutawayEnabled &&
              !isSaved;
      final cutaway = (item?.type == 'Mat' && isItemCutawayEnabled)
          ? (item?.cutaway ?? 0.1) + 1
          : 1;
      final ingredientCost = (ingredients[key] * item?.cost * cutaway);
      total += ingredientCost;
    });

    return total;
  }

  static double getRecipeSize(
    BuildContext context,
    Recipe recipe,
  ) {
    final items = recipe.itemsV2;
    var tempSize = 0.0;

    items.forEach((key, value) {
      var item = context.read<ItemProvider>().findById(key);

      if (item == null) {
        final recipe = context.read<RecipeProvider>().findById(key);
        if (recipe == null) return;
        item = Item.fromRecipe(context, recipe);
      }

      final itemSize = item.size;
      final recipeItemSize = ParseUtil.toNum(value);
      tempSize += recipeItemSize * ParseUtil.toNum(itemSize);
    });

    return tempSize;
  }

  static bool recipeHasItself(
    BuildContext context,
    String parentId,
    String toBeAddedId,
  ) {
    final recipeToBeAdded =
        context.read<RecipeProvider>().findById(toBeAddedId);
    // Recipe is trying to be added to itself
    if (parentId == toBeAddedId) {
      return true;
    }

    // Recipe is null
    if (recipeToBeAdded == null) {
      return false;
    }

    // Recipe doesn't have an ingredient yet
    if (recipeToBeAdded.itemsV2.isEmpty) {
      return false;
    }

    for (String id in recipeToBeAdded.itemsV2.keys) {
      final result = recipeHasItself(context, parentId, id);
      if (result) return true;
    }

    return false;
  }

  static Future<bool> saveRecipeWithLessSize(
    BuildContext context,
    Recipe recipe,
  ) async {
    var isConfirmed = true;
    var totalRecipeItemsSize = 0.0;

    totalRecipeItemsSize = RecipeUtil.getRecipeSize(context, recipe);

    final recipeSize = recipe.size ?? 0;

    if ((totalRecipeItemsSize < recipeSize * 0.85 ||
            totalRecipeItemsSize > recipeSize * 1.15) &&
        recipe.unit != 'pcs') {
      isConfirmed = await confirm(
        context,
        Text(
          'Saving a recipe with total ingredients of $totalRecipeItemsSize ${recipe.unit} in a recipe of ${recipe.size} ${recipe.unit}. Are you sure?',
        ),
      );
    }

    return isConfirmed;
  }
}
