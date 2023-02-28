import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/pos_item_ui.dart';
import 'package:stocklio_flutter/utils/extensions.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/pos_button_util.dart';
import 'package:stocklio_flutter/widgets/common/dialog_lists_download.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/search_text_field.dart';
import 'package:stocklio_flutter/widgets/common/show_archived_widget.dart';
import 'package:stocklio_flutter/widgets/shimmer/item_shimmer.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

import 'pos_item_list_tile.dart';

class POSItemsList extends StatefulWidget {
  const POSItemsList({
    Key? key,
  }) : super(key: key);

  @override
  State<POSItemsList> createState() => _POSItemsListState();
}

class _POSItemsListState extends State<POSItemsList> {
  final _scrollController = ScrollController();
  final _textController = TextEditingController();
  String _query = '';

  @override
  void initState() {
    final posItemUIProvider = context.read<POSItemUIProvider>();
    _textController.text = posItemUIProvider.posItemsQueryString;
    _query = posItemUIProvider.posItemsQueryString;
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final posItemUIProvider = context.watch<POSItemUIProvider>();
    final profileProvider = context.watch<ProfileProvider>();
    final itemsProvider = context.watch<ItemProvider>()..getAllItems();
    final recipeProvider = context.watch<RecipeProvider>()..getAllRecipes();

    final posItemProvider = context.watch<PosItemProvider>()
      ..posItems
      ..getArchivedPosItems();

    if (posItemProvider.isLoading ||
        itemsProvider.isLoading ||
        recipeProvider.isLoading) {
      return const ItemShimmer();
    }

    final accessLevel = profileProvider.profile.accessLevel;

    if (accessLevel < 3) {
      const textStyle = TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
      return Center(
        child: Responsive.isMobile(context)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    StringUtil.localize(context).text_upgrade1,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    StringUtil.localize(context).text_upgrade2,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ],
              )
            : Text(
                '${StringUtil.localize(context).text_upgrade1} ${StringUtil.localize(context).text_upgrade2}',
                textAlign: TextAlign.center,
                style: textStyle,
              ),
      );
    }

    final showArchived = posItemProvider.showArchived;

    final ingredients = _query.isNotEmpty
        ? context.read<ItemProvider>().search(_query, limit: 1)
        : [];
    var ingredientId = '';
    List<PosItem> posItemsByIngredientId = [];
    List<String> posItemIds = [];

    if (ingredients.isNotEmpty) ingredientId = ingredients.first.id ?? '';
    if (ingredientId.isNotEmpty) {
      posItemsByIngredientId = [
        ...posItemProvider.search(
          ingredientId,
          searchArchivedPosItems: showArchived,
        )
      ];
      posItemIds =
          posItemsByIngredientId.map((e) => e.id).cast<String>().toList();
    }

    final posItems = <PosItem>{
      ...posItemProvider.search(_query, searchArchivedPosItems: showArchived),
      ...posItemsByIngredientId,
    }.toList();

    final List<Item> items = [
      ...context.read<ItemProvider>().getAllItems(),
      ...context
          .read<RecipeProvider>()
          .getAllRecipes()
          .map((e) => Item.fromRecipe(context, e))
          .toList()
    ];

    if (_query.isEmpty) {
      posItems.sort((x, y) {
        final costPercentageX = POSButtonUtil.getItemCostPercent(
            context: context, items: items, posItem: x);
        final costPercentageY = POSButtonUtil.getItemCostPercent(
            context: context, items: items, posItem: y);
        return costPercentageY.compareTo(costPercentageX);
      });
    }

    Excel excel = generateExcelFile(posItems);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SearchTextField(
            controller: _textController,
            onChanged: (value) {
              setState(() {
                _query = value;
                posItemUIProvider.posItemsQueryString = value;
              });
              if (posItems.isNotEmpty) {
                _scrollController.jumpTo(0);
              }
            },
            hintText: StringUtil.localize(context).label_search_pos_buttons,
            clearCallback: () {
              setState(() {
                _textController.clear();
                _query = _textController.text;
                posItemUIProvider.posItemsQueryString = '';
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: ShowArchivedChip(
                showArchived: showArchived,
                onTap: () => posItemProvider.toggleShowArchived(),
              ),
            ),
            if (posItems.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => downloadLists(context,
                        StringUtil.localize(context).title_pos_item_excel,
                        excel: excel),
                    icon: Icon(
                      Icons.download_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        posItems.isEmpty
            ? Center(
                child:
                    Text(StringUtil.localize(context).label_no_pos_items_found))
            : Expanded(
                child: ListView.separated(
                  key: posItemUIProvider.pageStorageKey,
                  separatorBuilder: (context, index) => const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Divider(thickness: 2),
                  ),
                  controller: _scrollController,
                  itemCount: posItems.length,
                  itemBuilder: (context, index) {
                    return POSItemListTile(
                      index: index,
                      query: _query,
                      posItem: posItems[index],
                      isExpandedBySearch:
                          posItemIds.contains(posItems[index].id),
                    );
                  },
                ),
              ),
      ],
    );
  }

  Excel generateExcelFile(List<PosItem> posItems) {
    final profileProvider = context.read<ProfileProvider>()..profile;
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Recipe List'];
    excel.delete('Sheet1');

    final columnTitles = [
      'POS Item Name',
      'Price (${profileProvider.profile.currencyShort})',
      'Cost Percent'
    ];
    sheetObject.appendRow(columnTitles);

    for (var i = 0; i < posItems.length; i++) {
      final posiItemName = posItems[i].posData['name'];
      final posItemPrice =
          double.parse(posItems[i].posData['price'].toString()).toPrecision(2);
      final itemCostPercent = context
          .read<ItemProvider>()
          .getPOSItemCostPercent(posItems[i], context)
          .toPrecision(2);

      var posEntry = [posiItemName, posItemPrice, '$itemCostPercent%'];
      sheetObject.appendRow(posEntry);

      final itemsListIds = posItems[i].items.keys.toList();

      if (itemsListIds.isNotEmpty) {
        for (var j = 0; j < itemsListIds.length; j++) {
          final itemId = itemsListIds[j];
          var item = context.read<ItemProvider>().findById(itemId);

          if (item == null) {
            var recipe = context.read<RecipeProvider>().findById(itemId);
            if (recipe != null) {
              item ??= Item.fromRecipe(context, recipe);
            }
          }
          var ingredientSize = 0.0;
          var ingredientCost = 0.0;

          if (item != null) {
            ingredientSize =
                ParseUtil.toDouble(posItems[i].items[itemId] ?? 0) *
                    (item.size ?? 0);
            ingredientCost =
                ParseUtil.toDouble(posItems[i].items[itemId] ?? 0) * item.cost;

            final ingredientEntry = [
              '',
              item.name,
              ingredientSize.toPrecision(0),
              ingredientCost.toPrecision(2)
            ];
            sheetObject.appendRow(ingredientEntry);
          }
        }
      }
    }
    return excel;
  }
}
