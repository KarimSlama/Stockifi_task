import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/recipe.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/edit_recipe_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/tags_ui_provider.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/extensions.dart';
import 'package:stocklio_flutter/utils/formatters.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/number_util.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/recipe_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/search_item.dart';
import 'package:stocklio_flutter/widgets/common/selected_recipe_ingredient.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';
import 'package:stocklio_flutter/widgets/features/tags/tags.dart';
import '../providers/data/recipes.dart';
import '../widgets/common/confirm.dart';
import 'package:provider/provider.dart';
import '../providers/data/items.dart';
import '../widgets/common/value_textfield.dart';

class CreateRecipePage extends StatefulWidget {
  final Recipe? recipe;

  const CreateRecipePage({
    super.key,
    this.recipe,
  });

  @override
  CreateRecipePageState createState() => CreateRecipePageState();
}

class CreateRecipePageState extends State<CreateRecipePage>
    with AutomaticKeepAliveClientMixin {
  String? _selectedUnit;
  var _ingredients = <String, dynamic>{};
  final suggestionsKey = GlobalKey();

  List<String> _units = [];
  final _nameController = TextEditingController();
  final _sizeController = TextEditingController();
  final _searchController = TextEditingController();
  final _scrollController = ScrollController();
  final Map<String, FocusNode> _ingredientFocusNodes = {};
  late FocusNode _ingredientSearchFocusNode;

  final _nameFocusNode = FocusNode();

  final _sizeFocusNode = FocusNode();

  var isFormValid = true;

  @override
  void initState() {
    super.initState();

    _ingredientSearchFocusNode = FocusNode();
    final editRecipeUIProvider = context.read<EditRecipeUIProvider>();

    _nameController.text = editRecipeUIProvider.name!;
    _sizeController.text = (editRecipeUIProvider.size == null)
        ? ''
        : editRecipeUIProvider.size.toString();
    _searchController.text = editRecipeUIProvider.ingredientQuery;
    _selectedUnit = editRecipeUIProvider.selectedUnit;
    _ingredients = {...editRecipeUIProvider.ingredients};
    _units = editRecipeUIProvider.units;

    if (widget.recipe != null) {
      final sortedItemIds = widget.recipe!.sortedItemIds;

      _nameController.text = widget.recipe?.name ?? '';
      _sizeController.text = widget.recipe?.size.toString() ?? '';
      _selectedUnit = widget.recipe?.unit ?? '';
      var tempIngredientMap = widget.recipe?.itemsV2 ?? {};

      for (var itemId in [...sortedItemIds, ...tempIngredientMap.keys]) {
        if (!tempIngredientMap.containsKey(itemId)) continue;

        // TODO: look into why ingredients values are sometimes saved as null
        _ingredients.putIfAbsent(itemId, () => tempIngredientMap[itemId] ?? 0);
      }

      _ingredients.forEach((key, value) {
        _ingredientFocusNodes.addAll({key: FocusNode()});
      });

      if (widget.recipe != null) {
        context.read<TagsUIProvider>().tags = (widget.recipe?.tags ?? []);
      }
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _nameController.dispose();
    _sizeController.dispose();
    _scrollController.dispose();

    _nameFocusNode.dispose();
    _sizeFocusNode.dispose();

    _ingredientFocusNodes.forEach((key, value) {
      value.dispose();
    });
    _ingredientSearchFocusNode.dispose();
    super.dispose();
  }

  void saveRecipe() async {
    final isFormValid = _nameController.text.trim().isNotEmpty &&
        _sizeController.text.trim().isNotEmpty &&
        _selectedUnit != null &&
        _ingredients.isNotEmpty &&
        !_ingredients.values.contains(0);

    if (_sizeController.text.trim().isEmpty) {
      showToast(context, StringUtil.localize(context).message_invalid_size);
    }

    if (!isFormValid) return;

    Recipe recipe;
    bool saveRecipeWithLessSize;

    final tags = context.read<TagsUIProvider>().tags;
    final recipeCost = RecipeUtil.getTotalCostByIngredients(
        context, _ingredients,
        isSaved: true);

    if (widget.recipe != null) {
      recipe = widget.recipe!.copyWith(
        name: _nameController.text,
        size: int.parse(_sizeController.text),
        unit: _selectedUnit!,
        itemsV2: _ingredients,
        sortedItemIds: [..._ingredients.keys],
        cost: recipeCost,
        tags: tags,
      );
      saveRecipeWithLessSize =
          await RecipeUtil.saveRecipeWithLessSize(context, recipe);

      if (mounted && saveRecipeWithLessSize) {
        final result = await context
            .read<RecipeProvider>()
            .updateRecipe(recipe)
            .whenComplete(() {
          context.read<EditRecipeUIProvider>().resetRecipe();
          resetForm();
          Navigator.pop(context);
        });

        if (mounted) showToast(context, '$result ${recipe.name}');
      }
    } else {
      recipe = Recipe(
        name: _nameController.text,
        size: int.parse(_sizeController.text),
        unit: _selectedUnit!,
        itemsV2: _ingredients,
        cost: 0,
        sortedItemIds: [..._ingredients.keys],
        tags: tags,
      );

      saveRecipeWithLessSize =
          await RecipeUtil.saveRecipeWithLessSize(context, recipe);
      if (mounted && saveRecipeWithLessSize) {
        final result = await context
            .read<RecipeProvider>()
            .createRecipe(recipe)
            .whenComplete(() {
          context.read<EditRecipeUIProvider>().resetRecipe();
          resetForm();
          Navigator.pop(context);
        });
        if (mounted) showToast(context, '$result ${recipe.name}');
      }
    }
  }

  void resetForm() {
    _nameController.clear();
    _sizeController.clear();
    _selectedUnit = _units.first;
    _ingredients.clear();
    isFormValid = true;

    context.read<TagsUIProvider>().clearAllTags();
    setState(() {});
  }

  void onTap(String itemId) {
    final recipeHasItself = RecipeUtil.recipeHasItself(
      context,
      widget.recipe?.id ?? '',
      itemId,
    );

    if (recipeHasItself) {
      showDialog(
        context: context,
        barrierDismissible: true,
        builder: (context) {
          return AlertDialog(
            content: Text(
                StringUtil.localize(context).alert_recipe_cant_contain_itself),
          );
        },
      );

      return;
    }

    setState(() {
      _ingredients[itemId] = 0;
      _searchController.clear();
    });

    context.read<EditRecipeUIProvider>().putIngredient(itemId);
    context.read<EditRecipeUIProvider>().ingredientQuery = '';

    // Add new focus node
    _ingredientFocusNodes.putIfAbsent(itemId, () => FocusNode());

    _ingredientFocusNodes[itemId]!.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);

    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;
    final itemProvider = context.watch<ItemProvider>();
    final recipeProvider = context.watch<RecipeProvider>();
    final editRecipeUIProvider = context.read<EditRecipeUIProvider>();
    final profileProvider = context.watch<ProfileProvider>()..profile;
    final items = itemProvider.getAllItems();

    if (itemProvider.isLoadingItems || profileProvider.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
          child: Text(StringUtil.localize(context).label_no_items_found));
    }

    final colorPrimary = Theme.of(context).colorScheme.primary;

    final query = context.select<EditRecipeUIProvider, String>(
        (EditRecipeUIProvider editRecipeUIProvider) =>
            editRecipeUIProvider.ingredientQuery);

    final itemResults = itemProvider.search(query).take(30).toList();
    final recipeResults = recipeProvider
        .searchRecipes(query)
        .take(10)
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

    final suggestions = fuse.search(query).take(10).map((e) => e.item).toList();

    return StocklioScrollView(
      controller: _scrollController,
      child: Column(
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const SizedBox(height: 16),
          TextField(
            focusNode: _nameFocusNode,
            controller: _nameController,
            decoration: InputDecoration(
              labelText: StringUtil.localize(context).label_name,
              alignLabelWithHint: true,
              errorText: !isFormValid && _nameController.text.trim().isEmpty
                  ? StringUtil.localize(context).message_please_enter_name
                  : null,
            ),
            onChanged: (value) {
              context.read<EditRecipeUIProvider>().name = value;
              editRecipeUIProvider.recipe =
                  editRecipeUIProvider.recipe.copyWith(name: value);
            },
            onSubmitted: (_) {
              FocusScope.of(context).requestFocus(_sizeFocusNode);
            },
            textInputAction: TextInputAction.next,
          ),
          TextField(
              style: TextStyle(
                  color: AppTheme.instance.themeData.colorScheme.onPrimary),
              enabled: true,
              focusNode: _sizeFocusNode,
              controller: _sizeController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: StringUtil.localize(context).label_size,
                alignLabelWithHint: true,
                errorText: !isFormValid && _sizeController.text.trim().isEmpty
                    ? StringUtil.localize(context).message_invalid_size
                    : null,
              ),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^[1-9]\d{0,6}')),
                LengthLimitingTextInputFormatter(7),
              ],
              onChanged: (value) {
                context.read<EditRecipeUIProvider>().size = value;
              },
              textInputAction: TextInputAction.done,
              onSubmitted: (_) {
                _ingredientSearchFocusNode.requestFocus();
              }),
          DropdownButtonFormField<String>(
            decoration: InputDecoration(
              labelText: StringUtil.localize(context).label_unit,
              alignLabelWithHint: true,
              errorText: !isFormValid && _selectedUnit == null
                  ? StringUtil.localize(context).message_please_select_unit
                  : null,
            ),
            value: _selectedUnit,
            items: _units.map((e) {
              return DropdownMenuItem<String>(value: e, child: Text(e));
            }).toList(),
            onChanged: (value) {
              // This is for setting the selected unit
              setState(() {
                _selectedUnit = value;
              });
              _ingredientSearchFocusNode.requestFocus();
              // This line is for persisting state when dialog is closed
              context.read<EditRecipeUIProvider>().selectedUnit = value;
              editRecipeUIProvider.recipe =
                  editRecipeUIProvider.recipe.copyWith(unit: value);
            },
          ),
          const SizedBox(height: 16),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    StringUtil.localize(context).label_ingredients,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(StringUtil.localize(context).label_total_cost),
                    Text(
                        '${StringUtil.formatNumber(numberFormat, RecipeUtil.getTotalCostByIngredients(context, _ingredients, isSaved: false))}${profileProvider.profile.currencyShort}'),
                  ],
                ),
              ],
            ),
          ),
          if (_ingredients.entries.isEmpty)
            Center(
              child: Text(
                StringUtil.localize(context).label_please_add_ingredients,
                style: TextStyle(color: !isFormValid ? Colors.red : null),
              ),
            ),
          ..._ingredients.entries.map((e) {
            var item = items.firstWhereOrNull((item) => item.id == e.key);

            if (item == null) {
              var recipe = context.read<RecipeProvider>().findById(e.key);
              if (recipe != null) {
                item ??= Item.fromRecipe(context, recipe);
              }
            }
            final cutaway =
                item?.type == 'Mat' ? (item?.cutaway ?? 0.1) + 1 : 1;
            final ingredientCost = (_ingredients[e.key] * item?.cost * cutaway);
            final ingredientSize = (_ingredients[e.key] * item?.size);

            var ingredientSizeRounded = 0.0;
            var ingredientSizeRoundedString = '';

            final isInteger = NumberUtil.isInteger(ingredientSize);
            if (ingredientSize is num) {
              ingredientSizeRounded = ingredientSize.toDouble().toPrecision(2);
              ingredientSizeRoundedString =
                  ingredientSizeRounded.toStringAsFixed(2);
            }

            return (item == null)
                ? const SizedBox()
                : Container(
                    key: ValueKey(item.id),
                    margin: const EdgeInsets.only(bottom: 8),
                    child: Card(
                      shape: RoundedRectangleBorder(
                        side: BorderSide(color: colorPrimary, width: 2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      margin: EdgeInsets.zero,
                      color: Theme.of(context).colorScheme.background,
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            Expanded(
                              child: SelectedRecipeIngredient(item: item),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 68,
                              child: Center(
                                child: ValueTextField(
                                  textAlign: TextAlign.end,
                                  focusNode: _ingredientFocusNodes[e.key],
                                  value: (_ingredients[e.key] != null &&
                                          _ingredients[e.key] != 0)
                                      ? isInteger
                                          ? ingredientSize.toStringAsFixed(0)
                                          : ingredientSizeRoundedString
                                                  .endsWith('0')
                                              ? ingredientSizeRounded
                                                  .toStringAsFixed(1)
                                              : ingredientSizeRounded
                                                  .toStringAsFixed(2)
                                      : '',
                                  decoration: InputDecoration(
                                    labelText:
                                        StringUtil.localize(context).label_size,
                                    isDense: true,
                                    hintText:
                                        StringUtil.localize(context).label_size,
                                    errorText:
                                        !isFormValid && _ingredients[e.key] == 0
                                            ? StringUtil.localize(context)
                                                .label_enter_size
                                            : null,
                                    suffix: Text(' ${item.unit ?? ''}'),
                                  ),
                                  inputFormatters: item.unit == 'pcs'
                                      ? [
                                          DecimalInputFormatter(),
                                          LengthLimitingTextInputFormatter(6),
                                        ]
                                      : [
                                          FilteringTextInputFormatter.allow(
                                              RegExp(r'^[1-9]\d{0,5}')),
                                          LengthLimitingTextInputFormatter(6),
                                        ],
                                  onChanged: (value) {
                                    setState(() {
                                      final size = ParseUtil.toNum(value) /
                                          ParseUtil.toNum(
                                              item!.size.toString());

                                      _ingredients[e.key] = size;
                                      context
                                          .read<EditRecipeUIProvider>()
                                          .updateIngredientSize(e.key, size);
                                    });
                                  },
                                  onSubmitted: (_) {
                                    _ingredientSearchFocusNode.requestFocus();
                                  },
                                  keyboardType:
                                      const TextInputType.numberWithOptions(
                                    decimal: true,
                                  ),
                                ),
                              ),
                            ),
                            if (profileProvider
                                .profile.isItemCutawayEnabled) ...[
                              const SizedBox(width: 8),
                              SizedBox(
                                width: 48,
                                child: Padding(
                                  padding: const EdgeInsets.only(left: 8.0),
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.end,
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "CA(%)",
                                        textAlign: TextAlign.left,
                                        style: TextStyle(
                                            fontSize: 12,
                                            color: AppTheme.instance
                                                .disabledTextFormFieldLabelColor),
                                      ),
                                      Text(StringUtil.toPercentage(
                                          item.cutaway)),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 68,
                              child: Padding(
                                padding: const EdgeInsets.only(left: 8.0),
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.end,
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      StringUtil.localize(context).label_cost,
                                      textAlign: TextAlign.left,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: AppTheme.instance
                                              .disabledTextFormFieldLabelColor),
                                    ),
                                    Text(
                                        '${StringUtil.formatNumber(numberFormat, ingredientCost)}${profileProvider.profile.currencyShort}'),
                                  ],
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            IconButton(
                              onPressed: () {
                                setState(() {
                                  _ingredients.remove(e.key);
                                  context
                                      .read<EditRecipeUIProvider>()
                                      .removeIngredient(e.key);
                                });
                              },
                              icon: const Icon(Icons.delete),
                            ),
                          ],
                        ),
                      ),
                    ),
                  );
          }),
          Column(
            children: [
              TextField(
                focusNode: _ingredientSearchFocusNode,
                key: suggestionsKey,
                controller: _searchController,
                decoration: InputDecoration(
                  labelText:
                      StringUtil.localize(context).label_ingredient_search,
                  alignLabelWithHint: true,
                  suffixIcon: _searchController.text.isEmpty
                      ? null
                      : IconButton(
                          icon: Icon(
                            Icons.delete_outline,
                            color: Theme.of(context).colorScheme.primary,
                            size: 20,
                          ),
                          onPressed: () {
                            setState(() {
                              _searchController.clear();
                              context
                                  .read<EditRecipeUIProvider>()
                                  .ingredientQuery = _searchController.text;
                            });
                          },
                        ),
                ),
                onChanged: (value) {
                  context.read<EditRecipeUIProvider>().ingredientQuery = value;
                  Scrollable.ensureVisible(
                    suggestionsKey.currentContext!,
                    duration: const Duration(milliseconds: 500),
                  );
                },
              ),
              const SizedBox(height: 16),
              if (_searchController.text.isNotEmpty)
                ...suggestions.map((item) {
                  final itemCost = StringUtil.formatNumber(
                    context.read<ProfileProvider>().profile.numberFormat,
                    item.cost,
                  );

                  return Container(
                    decoration: const BoxDecoration(
                      border: Border(
                        bottom: BorderSide(width: 2, color: Colors.white12),
                      ),
                    ),
                    padding: const EdgeInsets.fromLTRB(2, 8, 2, 8),
                    child: SearchItem(
                      name: item.name ?? '',
                      query: query,
                      cost: itemCost,
                      size: item.size.toString(),
                      unit: item.unit.toString(),
                      variety: item.variety.toString(),
                      onTap: () => onTap(item.id!),
                    ),
                  );
                }).toList(),
            ],
          ),
          const SizedBox(height: 16),
          if (context.read<ProfileProvider>().profile.isItemTagsEnabled)
            const ItemTags(),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: StockifiButton.async(
              onPressed: saveRecipe,
              child: Text(StringUtil.localize(context).label_submit),
            ),
          ),
          const SizedBox(height: 16),
        ],
      ),
    );
  }

  @override
  bool get wantKeepAlive => true;
}
