// Flutter Packages
import 'package:flutter/material.dart';
import 'package:collection/collection.dart';
import 'package:fuzzy/fuzzy.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/base_item.dart';
import 'package:stocklio_flutter/providers/data/app_config.dart';
import 'package:stocklio_flutter/providers/ui/count_item_view_ui_provider.dart';
import 'package:stocklio_flutter/widgets/common/search_item.dart';
import 'package:stocklio_flutter/widgets/common/tutorial_button.dart';

// Models
import '../../../models/count_item.dart';
import '../../../models/item.dart';

// Providers
import '../../../providers/data/counts.dart';
import '../../../providers/data/count_items.dart';
import '../../../providers/data/items.dart';
import '../../../providers/data/recipes.dart';

// Screens
import '../../../providers/data/users.dart';

// Widgets
import '../../../utils/string_util.dart';

class SuggestionsList extends StatefulWidget {
  final String countId;
  final String areaId;
  final String query;
  final ScrollController? scrollController;
  final Function(BaseItem)? onItemSelected;
  final int? listLimit;
  final bool showEmptyResults;
  final bool isTextDetector;
  const SuggestionsList({
    super.key,
    required this.areaId,
    required this.countId,
    this.scrollController,
    this.query = '',
    this.onItemSelected,
    this.listLimit,
    this.showEmptyResults = true,
  }) : isTextDetector = false;
  const SuggestionsList.textDetector({
    super.key,
    required this.areaId,
    required this.countId,
    this.scrollController,
    this.query = '',
    this.onItemSelected,
    this.listLimit,
    this.showEmptyResults = true,
  }) : isTextDetector = true;

  @override
  State<SuggestionsList> createState() => _SuggestionsListState();
}

class _SuggestionsListState extends State<SuggestionsList> {
  late final ScrollController _scrollController;

  @override
  void initState() {
    _scrollController = widget.scrollController ?? ScrollController();
    super.initState();
  }

  @override
  void dispose() {
    if (_scrollController.hasClients) _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.read<ItemProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    final countItemProvider = context.read<CountItemProvider>();
    final countItemViewUIProvider = context.watch<CountItemViewUIProvider>();
    final items = itemProvider.getAllItems();
    final countItems = countItemProvider.getCountItems(widget.countId);

    List<Item> fuseItems = [];

    var itemResults = itemProvider
        .search(
          widget.query,
          countItemTypeFilters: countItemViewUIProvider.itemsTypeFilters,
          countItemVarietyFilters: countItemViewUIProvider.itemsVarietyFilters,
        )
        .take(30)
        .toList();

    if (itemResults.isEmpty && widget.isTextDetector) {
      itemResults = itemProvider
          .search(
            "",
            countItemTypeFilters: countItemViewUIProvider.itemsTypeFilters,
            countItemVarietyFilters:
                countItemViewUIProvider.itemsVarietyFilters,
          )
          .take(30)
          .toList();
    }

    fuseItems.addAll([...itemResults]);

    var recipeResults = recipeProvider
        .searchPrebatches(widget.query)
        .take(10)
        .map((e) => Item.fromRecipe(context, e))
        .toList();

    if (recipeResults.isEmpty && widget.isTextDetector) {
      recipeResults = recipeProvider
          .searchPrebatches("")
          .take(10)
          .map((e) => Item.fromRecipe(context, e))
          .toList();
    }

    fuseItems.addAll([...recipeResults]);

    // TODO: During clean up, find a way to remove these Fuzzy instances
    final fuse = Fuzzy<Item>(
      fuseItems,
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

    List<Item> results =
        fuse.search(widget.query).take(10).map((e) => e.item).toList();

    if (results.isEmpty && widget.isTextDetector) {
      results = fuse.search('').take(10).map((e) => e.item).toList();
    }

    Item? getItem(String id) => items.firstWhereOrNull((e) => e.id == id);

    // Retrieve item suggestions
    final tempSuggestions = <CountItem>[];

    void fetchSuggestions(String countId, int depth) {
      final previousCount =
          context.read<CountProvider>().getPreviousCount(countId);
      final previousCountId = previousCount?.id;

      if (previousCountId == null) return;

      final previousCountItems = context
          .read<CountItemProvider>()
          .getCountItems(previousCountId)
          .reversed
          .where((e) => e.areaId == widget.areaId)
          .toList();

      final countItemsInArea =
          countItems.where((e) => e.areaId == widget.areaId).toList();

      if (countItemsInArea.isNotEmpty) {
        void getSuggestions(String itemId) {
          var targetOccurrence = 0;
          for (var countItem in countItemsInArea) {
            if (countItem.itemId == itemId) targetOccurrence++;
          }

          var occurrence = 0;
          for (var i = 0; i < previousCountItems.length; i++) {
            if (previousCountItems[i].itemId == itemId) occurrence++;
            if (occurrence == targetOccurrence) {
              if (i > 0) tempSuggestions.add(previousCountItems[i - 1]);
              if (i > 1) tempSuggestions.add(previousCountItems[i - 2]);
              if (i < previousCountItems.length - 1) {
                tempSuggestions.add(previousCountItems[i + 1]);
              }
              if (i < previousCountItems.length - 2) {
                tempSuggestions.add(previousCountItems[i + 2]);
              }
              break;
            }
          }
        }

        for (var countItem in countItemsInArea.take(2)) {
          getSuggestions(countItem.itemId);
          if (tempSuggestions.isNotEmpty) break;
        }

        // Remove suggestions for items that have been counted recently
        final countItemsToRemove = countItemsInArea.take(4);
        tempSuggestions.removeWhere((suggestion) =>
            countItemsToRemove.any((e) => e.itemId == suggestion.itemId));
      } else {
        tempSuggestions.addAll(previousCountItems.take(3));
      }

      if (--depth > 0 && tempSuggestions.isEmpty) {
        fetchSuggestions(previousCountId, depth);
      }
    }

    if (widget.query.isEmpty) {
      final appConfig = context.watch<AppConfigProvider>().appConfig;
      fetchSuggestions(widget.countId, appConfig.suggestionsDepth);
    }

    for (var suggestion in tempSuggestions) {
      final itemIndex = results.indexWhere((e) => e.id == suggestion.itemId);
      if (itemIndex != -1) {
        results.removeAt(itemIndex);
      }
    }

    final suggestions = tempSuggestions
        .where((e) {
          final item = getItem(e.itemId);
          return item != null && !item.deleted;
        })
        .map((e) => getItem(e.itemId)!)
        .toSet()
        .toList();

    final newItems = results.where((e) => e.starred);
    final oldItems = results.where((e) => !e.starred);
    var list = [...newItems, ...suggestions, ...oldItems];

    if (widget.listLimit != null) {
      list = list.take(widget.listLimit!).toList();
    }

    return Scrollbar(
      controller: _scrollController,
      thumbVisibility: true,
      child: ListView.separated(
        padding: EdgeInsets.zero,
        controller: _scrollController,
        separatorBuilder: (context, index) => const Divider(thickness: 2),
        itemCount: (list.isEmpty && widget.showEmptyResults) ? 1 : list.length,
        itemBuilder: (context, index) {
          if (index == 0 &&
              list.isEmpty &&
              widget.showEmptyResults &&
              widget.query.isEmpty) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.start,
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                Icon(
                  Icons.search,
                  size: 100,
                  color: Theme.of(context).colorScheme.secondaryContainer,
                ),
                Text(
                  StringUtil.localize(context).label_type_to_find_an_item,
                  style: TextStyle(
                    fontSize: 18,
                    color: Theme.of(context).colorScheme.secondaryContainer,
                  ),
                ),
              ],
            );
          }

          if (list.isEmpty) {
            return const SizedBox.shrink();
          }

          final item = list[index];
          final itemCost = StringUtil.formatNumber(
            context.read<ProfileProvider>().profile.numberFormat,
            item.cost,
          );
          return SearchItem(
            name: item.name ?? '',
            cost: itemCost,
            size: item.size.toString(),
            unit: item.unit.toString(),
            variety: item.variety.toString(),
            query: widget.query,
            onTap: () => widget.onItemSelected?.call(item as BaseItem),
            trailing: item.starred
                ? const Icon(Icons.star)
                : index >= newItems.length &&
                        index < suggestions.length + newItems.length
                    ? item.itemsV2 != null
                        ? const SizedBox.shrink()
                        : Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              if (index == 0)
                                const TutorialButton(
                                  tutorialName:
                                      'Stockifi remembers the order you count your products to the next stock count',
                                ),
                              const Icon(Icons.blur_on),
                            ],
                          )
                    : const SizedBox(),
          );
        },
      ),
    );
  }
}
