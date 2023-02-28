import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/count_item_search_button.dart';
import 'package:stocklio_flutter/widgets/common/dialog_lists_download.dart';
import 'package:stocklio_flutter/widgets/common/filter_enums.dart';
import 'package:stocklio_flutter/widgets/common/search_text_field.dart';
import 'package:stocklio_flutter/widgets/features/items/item_list_tile.dart';
import 'package:stocklio_flutter/widgets/shimmer/item_shimmer.dart';
import '../../../providers/data/items.dart';
import '../../../screens/create_dialog.dart';
import 'package:provider/provider.dart';

import '../widgets/common/filters.dart';
import 'in_progress_new.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({Key? key}) : super(key: key);

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String _query = '';

  @override
  void initState() {
    final itemProvider = context.read<ItemProvider>();
    _textController.text = itemProvider.queryString;
    _query = itemProvider.queryString;
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
    final itemProvider = context.watch<ItemProvider>()
      ..getItems()
      ..getArchivedItems();
    final posItemProvider = context.watch<PosItemProvider>()
      ..posItems
      ..getArchivedPosItems();
    final recipeProvider = context.watch<RecipeProvider>()
      ..recipes
      ..getArchivedRecipes();

    if (itemProvider.isLoadingItems ||
        posItemProvider.isLoading ||
        recipeProvider.isLoading) {
      return const ItemShimmer();
    }

    final results = itemProvider.search(
      _query,
      filterSetting: FilterSetting.items,
      searchArchivedItems: itemProvider.showArchived,
    );

    if (_query.isEmpty) {
      results.sort((x, y) {
        final nameDiff = x.name!.compareTo(y.name!);
        final costDiff = x.cost.compareTo(y.cost);
        if (x.cost == 0 || y.cost == 0) {
          return costDiff != 0 ? costDiff : nameDiff;
        }
        return nameDiff;
      });
    }

    Excel excel = generateExcelFile(results);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: StockifiButton(
            onPressed: () {
              // TODO: Put this in a separate route similar to Edit Item and Edit POS Button
              Navigator.of(
                context,
                rootNavigator: true,
              ).push(
                InProgressRoute(
                  builder: (context) {
                    return const CreateDialog(
                      initialIndex: 0,
                    );
                  },
                ),
              );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(StringUtil.localize(context).label_add_item),
                const SizedBox(width: 2),
                const Icon(Icons.add_rounded, size: 20),
              ],
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SearchTextField(
            controller: _textController,
            onChanged: (value) {
              setState(() {
                _query = value;
                itemProvider.queryString = value;
              });
              _scrollController.jumpTo(0);
            },
            hintText: StringUtil.localize(context).hint_text_search_items,
            clearCallback: () {
              setState(() {
                _textController.clear();
                _query = _textController.text;
                itemProvider.queryString = '';
              });
            },
          ),
        ),
        Row(
          children: [
            const Expanded(
              child: ItemFilters(filterSetting: FilterSetting.items),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(
                horizontal: 8.0,
              ),
              child: Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => downloadLists(
                      context, StringUtil.localize(context).label_items_list,
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
        (results.isEmpty)
            ? Center(
                child: Text(StringUtil.localize(context).label_no_items_found))
            : Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    return CountItemSearchButton.onNotification(
                      context,
                      scrollNotification,
                    );
                  },
                  child: ListView.separated(
                    key: const PageStorageKey<String>('itemsScrollController'),
                    controller: _scrollController,
                    separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Divider(thickness: 2),
                    ),
                    itemCount: results.length + 1,
                    itemBuilder: (context, index) {
                      if (index == results.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            height: 68,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: ItemListTile(
                          item: results[index],
                          query: _textController.text,
                        ),
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }

  Excel generateExcelFile(List<Item> results) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Items List'];
    excel.delete('Sheet1');
    final columnTitles = [
      'Item Name',
      'Unit',
      'Size',
      'Cost',
    ];
    sheetObject.appendRow(columnTitles);

    for (var item in results) {
      var rowEntry = [item.name, item.unit, item.size, item.cost];
      sheetObject.appendRow(rowEntry);
    }
    return excel;
  }
}
