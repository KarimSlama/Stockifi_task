import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/wastage_item.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/data/wastage_items.dart';
import 'package:stocklio_flutter/providers/data/wastages.dart';
import 'package:stocklio_flutter/providers/ui/wastage_ui_provider.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/wastage_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/dialog_lists_download.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/search_text_field.dart';
import 'package:stocklio_flutter/widgets/features/wastage/wastage_item.dart';

class WastageView extends StatefulWidget {
  const WastageView({Key? key}) : super(key: key);

  @override
  State<WastageView> createState() => _WastageViewState();
}

class _WastageViewState extends State<WastageView> {
  final _textController = TextEditingController();
  late ScrollController _scrollController;
  late double initialOffset;
  String _query = '';

  @override
  void initState() {
    super.initState();
    final wastageUIProvider = context.read<WastageUIProvider>();
    _query = wastageUIProvider.queryString;
    _textController.text = wastageUIProvider.queryString;
    initialOffset = double.parse(wastageUIProvider.getPageStorageKey().value);
    _scrollController = ScrollController(initialScrollOffset: initialOffset);
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  String _formatDate(timestamp) => DateFormat("dd-MMM-''yy")
      .format(DateTime.fromMillisecondsSinceEpoch(timestamp));

  @override
  Widget build(BuildContext context) {
    final isWastageEnabled =
        context.watch<ProfileProvider>().profile.isWastageEnabled;
    if (!isWastageEnabled) {
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

    final wastageProvider = context.watch<WastageProvider>()..wastages;
    final itemProvider = context.watch<ItemProvider>()..getAllItems();
    final recipeProvider = context.watch<RecipeProvider>()
      ..getRecipesInclDeleted();
    final wastageItemsProvider = context.watch<WastageItemProvider>();

    if (wastageProvider.wastages.isEmpty) {
      return Center(
        child: Text(StringUtil.localize(context).label_no_wastage),
      );
    }

    final latestWastage = wastageProvider.latestWastage;

    if (latestWastage == null) {
      return Center(
        child: Text(StringUtil.localize(context).label_wastage_locked),
      );
    }

    final wastageItems =
        wastageItemsProvider.getWastageItems(latestWastage.id!);

    if (wastageProvider.isLoading ||
        itemProvider.isLoading ||
        wastageItemsProvider.isLoading ||
        recipeProvider.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    num alkoholfrittSubTotal = 0;
    num matSubTotal = 0;
    num prebatchesSubTotal = 0;

    for (var wastageItem in wastageItems) {
      var tempItem = itemProvider.findById(wastageItem.itemId);

      if (tempItem == null) {
        final recipe = recipeProvider.findById(wastageItem.itemId);

        if (recipe == null) continue;

        tempItem = Item.fromRecipe(context, recipe);
      }

      if (tempItem.type == "Alkoholfritt") {
        alkoholfrittSubTotal +=
            WastageUtil.getWastageTotal(wastageItem, tempItem);
      }

      if (tempItem.type == "Mat") {
        matSubTotal += WastageUtil.getWastageTotal(wastageItem, tempItem);
      }

      if (tempItem.type == "Recipe") {
        prebatchesSubTotal +=
            WastageUtil.getWastageTotal(wastageItem, tempItem);
      }

      wastageItem = wastageItem.copyWith(
          cost: WastageUtil.getWastageTotal(wastageItem, tempItem));
    }

    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;

    final itemResults = itemProvider
        .search(_query, searchDeletedItems: true)
        .where((element) =>
            element.type == 'Alkoholfritt' || element.type == 'Mat')
        .toList();

    final recipeResults = recipeProvider
        .searchPrebatches(_query, isDeletedItemsIncluded: true)
        .map((e) => Item.fromRecipe(context, e))
        .toList();

    final fuse = Fuzzy<Item>(
      [...itemResults, ...recipeResults],
      options: FuzzyOptions(
        keys: [
          WeightedKey(
            name: 'name',
            getter: (Item x) => x.name ?? '',
            weight: 1.0,
          ),
          WeightedKey(
            name: 'type',
            getter: (Item x) => x.type ?? '',
            weight: 0.3,
          ),
          WeightedKey(
            name: 'variety',
            getter: (Item x) => x.variety ?? '',
            weight: 0.3,
          ),
        ],
      ),
    );

    final results = fuse.search(_query).map((e) => e.item).toList();

    if (_query.isEmpty) {
      results.sort((x, y) {
        final wastageItemX = context
            .read<WastageItemProvider>()
            .getWastageItemByItemId(latestWastage.id!, x.id!);
        final wastageItemY = context
            .read<WastageItemProvider>()
            .getWastageItemByItemId(latestWastage.id!, y.id!);

        final wastageItemXCost = wastageItemX == null
            ? 0
            : WastageUtil.getWastageTotal(wastageItemX, x);
        final wastageItemYCost = wastageItemY == null
            ? 0
            : WastageUtil.getWastageTotal(wastageItemY, y);

        final nameDiff = x.name!.compareTo(y.name!);
        final costDiff = wastageItemYCost.compareTo(wastageItemXCost);

        return costDiff != 0 ? costDiff : nameDiff;
      });
    }

    Excel excel = generateExcelFile(wastageItems);

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            children: [
              Expanded(
                child: StockifiButton(
                  onPressed: null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'From ${_formatDate(latestWastage.startTime!)}',
                        style: const TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(width: 4.0),
                      const Icon(Icons.date_range,
                          color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: StockifiButton(
                  onPressed: null,
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: const [
                      Text(
                        'To Today',
                        style: TextStyle(color: Colors.white),
                        overflow: TextOverflow.ellipsis,
                      ),
                      SizedBox(width: 4.0),
                      Icon(Icons.date_range, color: Colors.white, size: 14),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Alkoholfritt Total:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
              Text(
                StringUtil.formatNumber(numberFormat, alkoholfrittSubTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                //TODO: CHECK IF MAT IS FOOD
                StringUtil.localize(context).label_food_total,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
              Text(
                StringUtil.formatNumber(numberFormat, matSubTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${StringUtil.localize(context).label_prebatch} Total:',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
              Text(
                StringUtil.formatNumber(numberFormat, prebatchesSubTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          child: Row(
            children: [
              const Spacer(),
              Text(
                StringUtil.localize(context).label_total,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
              const SizedBox(width: 16),
              Text(
                StringUtil.formatNumber(numberFormat,
                    alkoholfrittSubTotal + matSubTotal + prebatchesSubTotal),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    color: AppTheme.instance.disabledTextFormFieldLabelColor),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SearchTextField(
            controller: _textController,
            onChanged: (value) {
              setState(() {
                _query = value;
              });
              context.read<WastageUIProvider>().queryString = value;
              _scrollController.jumpTo(0);
            },
            hintText: StringUtil.localize(context).hint_text_search_wastage,
            clearCallback: () {
              setState(() {
                _textController.clear();
                _query = _textController.text;
                context.read<WastageUIProvider>().queryString = '';
              });
            },
          ),
        ),
        const SizedBox(height: 8),
        Padding(
          padding: const EdgeInsets.symmetric(
            horizontal: 8.0,
          ),
          child: Align(
            alignment: Alignment.centerRight,
            child: IconButton(
              onPressed: () =>
                  downloadLists(context, 'Wastage List', excel: excel),
              icon: Icon(
                Icons.download_rounded,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
          ),
        ),
        Expanded(
          child: ListView.builder(
            key: context.read<WastageUIProvider>().getPageStorageKey(),
            controller: _scrollController,
            itemBuilder: (context, index) {
              final wastageItem = context
                  .read<WastageItemProvider>()
                  .getWastageItemByItemId(
                      latestWastage.id!, results[index].id!);

              final itemProvider = context.watch<ItemProvider>()
                ..getItemsInclDeleted();
              final recipeProvider = context.watch<RecipeProvider>()
                ..getRecipesInclDeleted();

              if (itemProvider.isLoading || recipeProvider.isLoading) {
                return const Center(child: CircularProgressIndicator());
              }

              var isItemDeleted =
                  itemProvider.isItemDeleted(results[index].id!) ??
                      recipeProvider.isRecipeDeleted(results[index].id!) ??
                      true;

              if (wastageItem == null && isItemDeleted) {
                return const SizedBox();
              }

              return Column(
                children: [
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 8.0),
                    child: Divider(thickness: 2),
                  ),
                  WastageItemListTile(
                    item: results[index],
                    wastageId: latestWastage.id!,
                    query: _query,
                    wastageItem: wastageItem,
                    isItemDeleted: isItemDeleted,
                  ),
                ],
              );
            },
            itemCount: results.length,
          ),
        ),
      ],
    );
  }

  Excel generateExcelFile(List<WastageItem> wastageItems) {
    final wastageProvider = context.read<WastageProvider>()..wastages;
    final itemProvider = context.read<ItemProvider>()..getAllItems();
    final wastageItemsProvider = context.read<WastageItemProvider>();

    final latestWastage = wastageProvider.latestWastage;
    final wastageItems =
        wastageItemsProvider.getWastageItems(latestWastage!.id!);

    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Wastage List'];
    excel.delete('Sheet1');
    final columnTitles = [
      'Wastage Item',
      'Unit',
      'Size',
      'Total Cost',
    ];
    sheetObject.appendRow(columnTitles);

    for (var wastageItem in wastageItems) {
      final tempItem = itemProvider.findById(wastageItem.itemId);
      if (tempItem == null) continue;

      wastageItem = wastageItem.copyWith(
          cost: WastageUtil.getWastageTotal(wastageItem, tempItem));

      var itemEntry = [
        tempItem.name,
        tempItem.unit,
        tempItem.size,
        wastageItem.cost
      ];

      sheetObject.appendRow(itemEntry);

      final sortedMap = Map.fromEntries(
          (wastageItem.items ?? {}).entries.toList()
            ..sort((e1, e2) => e2.value.compareTo(e1.value)));
      final wastageItemsList = sortedMap.entries.toList();

      for (var i = 0; i < wastageItemsList.length; i++) {
        num partSize;
        double cost;

        partSize =
            ParseUtil.toNum(wastageItemsList[i].value) * (tempItem.size ?? 0);
        cost = ParseUtil.toDouble(wastageItemsList[i].value) * tempItem.cost;

        final wastageItemEntry = ['', tempItem.name, partSize, cost];
        sheetObject.appendRow(wastageItemEntry);
      }
    }
    return excel;
  }
}
