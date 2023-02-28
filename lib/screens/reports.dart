import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/recipe.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/utils/enums.dart';
import 'package:stocklio_flutter/utils/file_util.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/recipe_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/download_tile.dart';
import '../providers/data/items.dart';
import '../providers/data/pos_items.dart';
import 'package:provider/provider.dart';

class ReportsPage extends StatelessWidget {
  const ReportsPage({Key? key, this.profileId}) : super(key: key);

  final String? profileId;

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final recipeProvider = context.watch<RecipeProvider>()..getAllRecipes();
    final posItemProvider = context.watch<PosItemProvider>();

    final items = itemProvider.getAllItems(profileId);
    final posItems = posItemProvider.posItems;
    final menuItems = recipeProvider.menuItems;
    final prebatches = recipeProvider.prebatches;

    if (itemProvider.isLoading ||
        recipeProvider.isLoading ||
        posItemProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return ReportsView(
      items: items,
      menuItems: menuItems,
      prebatches: prebatches,
      posItems: posItems,
    );
  }
}

class ReportsView extends StatelessWidget {
  final List<Item> items;
  final List<PosItem> posItems;
  final List<Recipe> menuItems;
  final List<Recipe> prebatches;

  const ReportsView({
    Key? key,
    required this.items,
    required this.posItems,
    required this.menuItems,
    required this.prebatches,
  }) : super(key: key);

  void downloadPosItemsReport(BuildContext context) {
    final recipes = [...menuItems, ...prebatches];

    final itemTypes = ['wine', 'drink'];
    var excel = Excel.createExcel();

    for (var i = 0; i < posItems.length; i++) {
      final posItem = posItems[i];
      final ingredients = {...posItem.items};

      void parseRecipe(Recipe recipe, num quantity) {
        final itemsV2 = recipe.itemsV2;
        for (var itemId in itemsV2.keys) {
          final item = items.firstWhereOrNull((x) => x.id == itemId);
          final recipe = recipes.firstWhereOrNull((x) => x.id == itemId);
          if (item != null) {
            final value = ParseUtil.toNum(ingredients[itemId] ?? 0);
            ingredients[itemId] = value + itemsV2[itemId] * quantity;
          } else if (recipe != null) {
            parseRecipe(recipe, itemsV2[itemId]);
          }
        }
      }

      for (var itemId in [...ingredients.keys]) {
        final recipe = recipes.firstWhereOrNull((x) => x.id == itemId);
        if (recipe != null) {
          parseRecipe(recipe, ingredients[itemId] ?? 0);
          ingredients.remove(itemId);
        }
      }

      posItems[i] = posItem.copyWith(items: ingredients);
    }

    for (var itemType in itemTypes) {
      var sheetObject = excel[
          '${itemType[0].toUpperCase()}${itemType.substring(1)} Profit Report'];
      var filteredItems = posItems.where((e) {
        var isWine = false;

        final itemIds = e.items.keys;

        for (var itemId in itemIds) {
          final type = items.firstWhere((e) => e.id == itemId).type;

          if (type == 'Vin' || type == 'Starkvin') {
            isWine = true;
          }
        }

        isWine = isWine && !(itemIds.length > 1);

        return itemType == 'wine' ? isWine : !isWine;
      }).map((posItem) {
        posItem = posItem.copyWith(cost: 0, costPerItem: {});

        for (var itemId in posItem.items.keys) {
          final item = items.firstWhere((e) => e.id == itemId);
          final itemCost = item.cost;

          final costPerItem = itemCost * _toNumber(posItem.items[itemId]);

          posItem = posItem.copyWith(cost: posItem.cost + costPerItem);
          posItem.costPerItem[itemId] = costPerItem;
        }

        return posItem;
      }).toList();

      final posItemsVarieties = <String, String>{};
      for (var posItem in filteredItems) {
        for (var itemId in posItem.items.keys) {
          final existingItem = items.firstWhereOrNull((e) => e.id == itemId);
          if (existingItem != null) {
            posItemsVarieties[posItem.id!] = existingItem.variety!;
            break;
          }
        }
      }

      filteredItems.sort((x, y) {
        final priceX = ParseUtil.toNum(x.posData['price']);
        final priceY = ParseUtil.toNum(y.posData['price']);
        final totalPriceX = x.cost / (priceX * 0.8);
        final totalPriceY = y.cost / (priceY * 0.8);
        final priceDiff = totalPriceY.compareTo(totalPriceX);

        final varietyX = posItemsVarieties[x.id];
        final varietyY = posItemsVarieties[y.id];
        final varietyDiff = varietyX != null && varietyY != null
            ? varietyX.compareTo(varietyY)
            : 0;

        return itemType == 'wine' && varietyDiff != 0 ? varietyDiff : priceDiff;
      });

      final firstRow = [
        'POS Name',
        'Price',
        'Stockifi Name',
        'Quantity',
        'Total Cost',
        'Cost %',
      ];
      if (itemType == 'wine') firstRow.insert(3, 'Stockifi Variety');
      sheetObject.appendRow(firstRow);

      String? lastVariety;
      for (var posItem in filteredItems) {
        final name = posItem.posData['name'];
        final price = ParseUtil.toNum(posItem.posData['price']);

        if (itemType == 'wine' &&
            lastVariety != posItemsVarieties[posItem.id]) {
          sheetObject.appendRow(['']);
          sheetObject.appendRow([posItemsVarieties[posItem.id] ?? 'Unknown']);
          lastVariety = posItemsVarieties[posItem.id];
        }

        var isFirstItem = true;

        for (final itemId in posItem.items.keys) {
          final item = items.firstWhere((e) => e.id == itemId);
          final value = _toNumber(posItem.items[itemId]);

          final quantity = isInteger(value)
              ? '${value}x'
              : '${(value * item.size!).round()}${item.unit}';

          final total = posItem.cost;
          final totalPrice = price != 0 ? total / (price * 0.8) : 0;

          double round(num value) => (value * 100).round() / 100;

          final sheetRow = [
            isFirstItem ? name : '',
            isFirstItem ? price : '',
            item.name,
            quantity,
            isFirstItem ? round(total) : '',
            isFirstItem ? round(totalPrice) : '',
          ];
          if (itemType == 'wine') sheetRow.insert(3, item.variety);
          sheetObject.appendRow(sheetRow);

          isFirstItem = false;
        }
      }
    }
    excel.delete('Sheet1');

    const fileName = 'stockifi wine & drink report.xlsx';
    FileUtil.saveExcel(context, fileName, excel, true);
  }

  void downloadRecipesList(BuildContext context, RecipeType recipeType) {
    final data = [];
    data.add([
      'Name',
      'Size',
      'Unit',
      'Cost',
      'CostPer1000',
      'Items',
      'PartSize',
      'ItemSize',
      'ItemUnit',
      'ItemCost',
      'PartSize / ItemSize * ItemCost',
    ]);

    final recipes =
        recipeType == RecipeType.prebatch ? [...prebatches] : [...menuItems];

    for (var recipe in recipes) {
      final name = recipe.name;
      final size = recipe.size ?? 0;
      final unit = recipe.unit ?? '/';
      final recipeData = [];
      var isRecipeInvalid = false;

      var isFirstItem = true;

      recipe.itemsV2.forEach((key, value) {
        final item = items.firstWhereOrNull((e) => e.id == key);

        if (item == null) return;

        if (item.deleted) {
          isRecipeInvalid = true;
        }

        final itemSize = item.size ?? 0;
        final partSize = ParseUtil.toNum(value) * itemSize;
        final itemCost = item.cost;
        final recipeCost = RecipeUtil.getRecipeCost(context, recipe);

        divide(num x, num y) => y != 0 ? x / y : 0;

        recipeData.add([
          isFirstItem ? name : '',
          isFirstItem ? size : '',
          isFirstItem ? unit : '',
          isFirstItem ? recipeCost : '',
          isFirstItem ? divide(recipeCost, size) * 1000 : '',
          item.name,
          partSize,
          itemSize,
          item.unit,
          itemCost,
          (partSize / itemSize) * itemCost,
        ]);

        isFirstItem = false;
      });

      if (!isRecipeInvalid) data.addAll(recipeData);
    }

    downloadReport(
        context,
        '${StringUtil.localize(context).label_stockifi_recipes_list_download}.xlsx',
        data);
  }

  void downloadItemsList(BuildContext context) {
    final data = [];

    data.add([
      StringUtil.localize(context).label_name,
      StringUtil.localize(context).label_size,
      StringUtil.localize(context).label_unit,
      StringUtil.localize(context).label_type,
      StringUtil.localize(context).label_variety,
      StringUtil.localize(context).label_cost
    ]);
    for (var item in items.where((e) => !e.deleted)) {
      data.add([
        item.name,
        item.size,
        item.unit,
        item.type,
        item.variety,
        item.cost
      ]);
    }
    downloadReport(
        context,
        '${StringUtil.localize(context).label_stockifi_item_list_download}.xlsx',
        data);
  }

  void downloadReport(
    BuildContext context,
    String fileName,
    List data,
  ) async {
    var excel = Excel.createExcel();
    var sheetObject = excel['Sheet1'];
    for (var row in data) {
      sheetObject.appendRow(row);
    }

    FileUtil.saveExcel(context, fileName, excel, true);
  }

  num _toNumber(var number) {
    return number is num ? number : num.parse(number);
  }

  bool isInteger(num value) => value is int || value == value.roundToDouble();

  @override
  Widget build(BuildContext context) {
    if (items.isEmpty) {
      return Center(
          child: Text(StringUtil.localize(context).label_no_items_found));
    }

    return Column(
      children: [
        DownloadTile(
          title: Text(StringUtil.localize(context).label_items_list),
          onTap: () => downloadItemsList(context),
        ),
        if (prebatches.isNotEmpty)
          DownloadTile(
            title: Text(StringUtil.localize(context).label_prebatches_list),
            onTap: () => downloadRecipesList(context, RecipeType.prebatch),
          ),
        if (menuItems.isNotEmpty)
          DownloadTile(
            title: Text(StringUtil.localize(context).label_dishes_list),
            onTap: () => downloadRecipesList(context, RecipeType.dish),
          ),
        if (posItems.isNotEmpty)
          DownloadTile(
            title: Text(StringUtil.localize(context).label_profit_report),
            onTap: () => downloadPosItemsReport(context),
          ),
      ],
    );
  }
}
