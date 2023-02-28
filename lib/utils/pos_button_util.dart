import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/utils/extensions.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

import '../models/item.dart';

class POSButtonUtil {
  static num getTotalCost(PosItem posItem, BuildContext context) {
    var total = 0.0;

    posItem.items.forEach((key, value) {
      var item = context.read<ItemProvider>().findById(key);

      if (item == null) {
        var recipe = context.read<RecipeProvider>().findById(key);
        if (recipe != null) {
          item ??= Item.fromRecipe(context, recipe);
        }
      }

      if (item == null) return;

      final ingredientCost = posItem.items[key]! * item.cost;
      total += ingredientCost;
    });

    return total;
  }

  static num getItemCostPercent({
    required BuildContext context,
    required List<Item> items,
    required PosItem posItem,
  }) {
    final itemPrice = ParseUtil.toNum(posItem.posData['price']) * 0.8;

    var totalCost = 0.0;
    for (var itemId in posItem.items.keys) {
      final item = items.firstWhereOrNull((x) => x.id == itemId);

      if (item != null) {
        final ingredientCost =
            ParseUtil.toNum(posItem.items[itemId] ?? 0) * item.cost;
        totalCost += ingredientCost;
      }
    }

    if (itemPrice == 0 || totalCost == 0) return 0;

    final itemCostPercent = totalCost / itemPrice * 100;

    return itemCostPercent.toPrecision(2);
  }
}
