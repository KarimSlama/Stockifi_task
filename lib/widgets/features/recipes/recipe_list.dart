// Flutter Packages
import 'package:collection/collection.dart';
import 'package:excel/excel.dart';
import 'package:flutter/material.dart';
// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/ui/recipe_ui_provider.dart';
import 'package:stocklio_flutter/utils/enums.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/recipe_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/count_item_search_button.dart';
import 'package:stocklio_flutter/widgets/common/dialog_lists_download.dart';

import 'package:stocklio_flutter/widgets/common/search_text_field.dart';
import 'package:stocklio_flutter/widgets/common/show_archived_widget.dart';

// Models
import '../../../models/item.dart';
import '../../../models/recipe.dart';
// Providers
import '../../../providers/data/recipes.dart';
// Screens
import '../../../screens/create_dialog.dart';
import '../../../screens/in_progress_new.dart';
// Widgets
import 'recipe_list_tile.dart';

class RecipesList extends StatefulWidget {
  final List<Recipe> recipes;
  final List<Item> items;
  final RecipeType recipeType;

  const RecipesList({
    super.key,
    required this.recipes,
    required this.items,
  }) : recipeType = RecipeType.prebatch;

  const RecipesList.dishes({
    super.key,
    required this.recipes,
    required this.items,
  }) : recipeType = RecipeType.dish;

  @override
  State<RecipesList> createState() => _RecipesListState();
}

class _RecipesListState extends State<RecipesList> {
  final _textController = TextEditingController();
  late ScrollController _scrollController;

  String _query = '';

  @override
  void initState() {
    final recipeUIProvider = context.read<RecipeUIProvider>();
    _query = recipeUIProvider.queryString;
    _textController.text = recipeUIProvider.queryString;
    _scrollController = ScrollController();
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
    final recipeUIProvider = context.watch<RecipeUIProvider>();
    final recipeProvider = context.watch<RecipeProvider>()..getAllRecipes();
    final itemProvider = context.watch<ItemProvider>()..getAllItems();

    final items = itemProvider.search(_query, limit: 1);
    final showArchived = recipeProvider.showArchived;

    var ingredientId = '';
    List<Recipe> recipesByIngredientId = [];
    List<String>? recipeIds = [];

    if (items.isNotEmpty) ingredientId = items.first.id ?? '';
    if (ingredientId.isNotEmpty) {
      recipesByIngredientId = (RecipeType.prebatch == widget.recipeType)
          ? [
              ...recipeProvider.searchPrebatches(
                ingredientId,
                searchArchivedPrebatches: showArchived,
              )
            ]
          : [
              ...recipeProvider.searchDishes(
                ingredientId,
                searchArchivedDishes: showArchived,
              )
            ];
      recipeIds =
          recipesByIngredientId.map((e) => e.id).cast<String>().toList();
    }

    final recipes = (RecipeType.prebatch == widget.recipeType)
        ? <Recipe>{
            ...recipeProvider.searchPrebatches(
              _query,
              searchArchivedPrebatches: showArchived,
            ),
            ...recipesByIngredientId,
          }.toList()
        : <Recipe>{
            ...recipeProvider.searchDishes(
              _query,
              searchArchivedDishes: showArchived,
            ),
            ...recipesByIngredientId,
          }.toList();

    final results = recipes.map((recipe) {
      final recipeCost = RecipeUtil.getRecipeCost(context, recipe);

      final newRecipe = recipe.copyWith(cost: recipeCost);

      return newRecipe;
    }).toList();

    var zeroCostRecipe = <Recipe>[];
    var nonZeroCostRecipe = <Recipe>[];

    for (var recipe in results) {
      if (recipe.cost == 0) {
        zeroCostRecipe.add(recipe);
      } else {
        nonZeroCostRecipe.add(recipe);
      }
    }

    zeroCostRecipe.sort(((a, b) => a.name!.compareTo(b.name!)));
    nonZeroCostRecipe.sort(((a, b) => a.name!.compareTo(b.name!)));

    final sortedRecipeList = <Recipe>[...zeroCostRecipe, ...nonZeroCostRecipe];

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: StockifiButton(
            onPressed: () {
              // TODO: Put this in a separate route similar to Edit Item and Edit POS Button
              final navigator = Navigator.of(context, rootNavigator: true);

              (RecipeType.prebatch == widget.recipeType)
                  ? navigator.push(
                      InProgressRoute(builder: (context) {
                        return const CreateDialog(initialIndex: 1);
                      }),
                    )
                  : navigator.push(
                      InProgressRoute(builder: (context) {
                        return const CreateDialog(initialIndex: 2);
                      }),
                    );
            },
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text((RecipeType.prebatch == widget.recipeType)
                    ? StringUtil.localize(context).label_add_prebatch
                    : StringUtil.localize(context).label_add_dish),
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
            onChanged: (value) async {
              _updateQueryString(value).whenComplete(() {
                _scrollTop();
              });
            },
            hintText: (RecipeType.prebatch == widget.recipeType)
                ? StringUtil.localize(context).hint_text_search_prebatches
                : StringUtil.localize(context).hint_text_search_menu_items,
            clearCallback: () {
              setState(() {
                _textController.clear();
                _query = _textController.text;
                recipeUIProvider.queryString = '';
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
                onTap: () => recipeProvider.toggleShowArchived(),
              ),
            ),
            if (widget.recipes.isNotEmpty)
              Padding(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8.0,
                ),
                child: Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => widget.recipeType == RecipeType.prebatch
                        ? downloadLists(context,
                            StringUtil.localize(context).label_prebatches_list,
                            excel: generateExcelFile(sortedRecipeList))
                        : downloadLists(context,
                            StringUtil.localize(context).label_dishes_list,
                            excel: generateExcelFile(sortedRecipeList)),
                    icon: Icon(
                      Icons.download_rounded,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),
              ),
          ],
        ),
        (widget.recipes.isEmpty)
            ? Center(
                child: Text((RecipeType.prebatch == widget.recipeType)
                    ? StringUtil.localize(context).label_no_prebatches_found
                    : StringUtil.localize(context).label_no_dishes_found))
            : Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    return CountItemSearchButton.onNotification(
                      context,
                      scrollNotification,
                    );
                  },
                  child: ListView.separated(
                    key: RecipeType.prebatch == widget.recipeType
                        ? const PageStorageKey<String>(
                            'prebatchScrollController')
                        : const PageStorageKey<String>(
                            'dishesScrollController'),
                    controller: _scrollController,
                    separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Divider(thickness: 2),
                    ),
                    itemCount: sortedRecipeList.length + 1,
                    itemBuilder: (context, index) {
                      if (index == sortedRecipeList.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            height: 68,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: widget.recipeType == RecipeType.prebatch
                            ? RecipeListTile(
                                recipe: sortedRecipeList[index],
                                index: index,
                                query: _query,
                                isExpandedBySearch: (recipeIds?.contains(
                                            sortedRecipeList[index].id) ??
                                        false) &&
                                    _query.isNotEmpty,
                              )
                            : RecipeListTile.dishes(
                                recipe: sortedRecipeList[index],
                                index: index,
                                query: _query,
                                isExpandedBySearch: (recipeIds?.contains(
                                            sortedRecipeList[index].id) ??
                                        false) &&
                                    _query.isNotEmpty,
                              ),
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }

  void _scrollTop() {
    _scrollController.animateTo(
      _scrollController.position.minScrollExtent,
      duration: const Duration(seconds: 2),
      curve: Curves.fastOutSlowIn,
    );
  }

  Future<void> _updateQueryString(String value) async {
    setState(() {
      _query = value;
      context.read<RecipeUIProvider>().queryString = value;
    });
  }

  Excel generateExcelFile(List<Recipe> recipes) {
    var excel = Excel.createExcel();
    Sheet sheetObject = excel['Recipe List'];
    excel.delete('Sheet1');
    var columnTitle = (RecipeType.prebatch == widget.recipeType)
        ? 'Prebatch Name'
        : 'Dish Name';
    final data = [];
    data.add([columnTitle, 'Unit', 'Size', 'Cost']);

    for (var recipe in recipes) {
      var recipeData = [];
      var isFirstItem = true;

      final recipeItemsList = (recipe.itemsV2).entries.toList();
      var isRecipeInvalid = false;
      if (recipeItemsList.isEmpty) continue;
      for (var i = 0; i < recipeItemsList.length; i++) {
        final ingredientId = recipeItemsList[i].key;

        var item = widget.items.firstWhereOrNull((e) => e.id == ingredientId);
        if (item == null) {
          continue;
        }
        if (item.deleted == true) {
          isRecipeInvalid = true;
        }

        num partSize =
            ParseUtil.toNum(recipeItemsList[i].value) * (item.size ?? 0);
        double cost = ParseUtil.toDouble(recipeItemsList[i].value) * item.cost;
        if (isFirstItem) {
          recipeData.add([recipe.name, recipe.unit, recipe.size, recipe.cost]);
        }
        isFirstItem = false;
        recipeData.add(['', item.name, partSize, cost]);
      }
      if (!isRecipeInvalid) {
        data.addAll(recipeData);
      }
    }
    for (var i = 0; i < data.length; i++) {
      sheetObject.appendRow(data[i]);
    }
    return excel;
  }
}
