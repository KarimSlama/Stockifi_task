import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/providers/data/admin.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/tasks.dart';
import 'package:stocklio_flutter/providers/ui/pos_item_ui.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/extensions.dart';
import 'package:stocklio_flutter/utils/formatters.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/pos_button_util.dart';
import 'package:stocklio_flutter/widgets/common/base_button.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/search_item.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';

import '../../../providers/data/users.dart';
import '../../../utils/string_util.dart';
import '../../common/confirm.dart';
import '../../common/page.dart';
import '../../common/value_textfield.dart';

class EditPOSItemDialog extends StatefulWidget {
  const EditPOSItemDialog({
    Key? key,
    required this.posItem,
    this.taskId,
  }) : super(key: key);

  final PosItem posItem;
  final String? taskId;

  @override
  State<EditPOSItemDialog> createState() => _EditPOSItemDialogState();
}

class _EditPOSItemDialogState extends State<EditPOSItemDialog> {
  final suggestionsKey = GlobalKey();
  final Map<String, FocusNode> _itemFocusNodes = {};
  final Map<String, FocusNode> _unitFocusNodes = {};
  final _searchController = TextEditingController();
  final _nameController = TextEditingController();
  final _articleGroupController = TextEditingController();
  final _sellingPriceController = TextEditingController();
  final FocusNode _itemSearchFocusNode = FocusNode();

  var isFormValid = true;
  var isItemUnconnected = false;

  late PosItem _posItem;

  @override
  void initState() {
    _posItem = widget.posItem;

    _posItem.items.forEach((key, value) {
      _itemFocusNodes.addAll({key: FocusNode()});
      _unitFocusNodes.addAll({key: FocusNode()});
    });

    _nameController.text = _posItem.posData['name'].toString();
    _articleGroupController.text = _posItem.posData['articleGroup']['name'];
    _sellingPriceController.text =
        double.parse(_posItem.posData['price'].toString())
            .toPrecision(2)
            .toString();

    super.initState();
  }

  @override
  void dispose() {
    _itemFocusNodes.forEach((key, value) {
      value.dispose();
    });
    _unitFocusNodes.forEach((key, value) {
      value.dispose();
    });
    _itemSearchFocusNode.dispose();
    super.dispose();
  }

  void saveAndPop() async {
    final taskId = widget.taskId ??
        context
            .read<TaskProvider>()
            .findTask(path: '/edit-pos-item/${_posItem.id}')
            ?.id;

    await context
        .read<PosItemProvider>()
        .updatePOSItem(_posItem, taskId: taskId);
    if (mounted) Navigator.pop(context);
    if (mounted) {
      showToast(context, 'POS Item updated, ${_posItem.posData['name'] ?? ''}');
    }
  }

  void savePOSItem() async {
    final List<Item> items = [
      ...context.read<ItemProvider>().getAllItems(),
      ...context
          .read<RecipeProvider>()
          .getAllRecipes()
          .map((e) => Item.fromRecipe(context, e))
          .toList()
    ];
    final itemCostPercent = POSButtonUtil.getItemCostPercent(
      context: context,
      items: items,
      posItem: _posItem,
    );

    var isConfirmed = false;

    if (itemCostPercent >= 50) {
      isConfirmed = await confirm(
        context,
        RichText(
          text: TextSpan(
            children: <TextSpan>[
              TextSpan(
                text:
                    StringUtil.localize(context).message_save_edit_item_dialog1,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              TextSpan(
                text:
                    StringUtil.localize(context).message_save_edit_item_dialog2,
                style: Theme.of(context).textTheme.titleLarge!.copyWith(
                      color: _getCostPercentColor(itemCostPercent),
                    ),
              ),
            ],
          ),
        ),
      );
      if (!isConfirmed) return;
      if (isConfirmed) {
        saveAndPop();
      }
    } else {
      saveAndPop();
    }
  }

  Color? _getCostPercentColor(num costPercent) {
    if (costPercent < 50) {
      return Colors.green;
    } else if (costPercent >= 50) {
      return Colors.orange;
    }

    return null;
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;
    final itemProvider = context.watch<ItemProvider>();
    final recipeProvider = context.watch<RecipeProvider>()..recipes;
    final posItemProvider = context.watch<PosItemProvider>()..posItems;
    final posItemUIProvider = context.read<POSItemUIProvider>();
    final items = itemProvider.getItems();
    final profileProvider = context.watch<ProfileProvider>()..profile;

    final itemCostPercent =
        context.read<ItemProvider>().getPOSItemCostPercent(_posItem, context);

    if (itemProvider.isLoadingItems ||
        posItemProvider.isLoading ||
        recipeProvider.isLoading) {
      return const Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    if (itemProvider.isLoadingItems) {
      return const Center(child: CircularProgressIndicator());
    }

    if (items.isEmpty) {
      return Center(
          child: Text(StringUtil.localize(context).label_no_items_found));
    }

    var query = context.select<POSItemUIProvider, String>(
      (POSItemUIProvider posItemUIProvider) =>
          posItemUIProvider.itemsQueryString,
    );

    if (query.isEmpty) {
      query = _posItem.posData['name'].toString();
    }

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

    final suggestions = fuse
        .search(query)
        .take(10)
        .map((e) => e.item)
        .where((e) => !_posItem.items.keys.contains(e.id));

    final isAdmin =
        context.select<AuthProvider, bool>((value) => value.isAdmin);
    final isAdminPowersEnabled = context
        .select<AdminProvider, bool>((value) => value.isAdminPowersEnabled);
    final isCheckboxVisible = (isAdmin && isAdminPowersEnabled) ||
        _posItem.items.isEmpty && _posItem.posData['price'] == 0;

    return StocklioModal(
      title: StringUtil.localize(context).label_edit_pos_button,
      actions: [
        IconButton(
          onPressed: () async {
            final isConfirmed = await confirm(
                context,
                Text(StringUtil.localize(context)
                    .message_confirm_archive_dialog
                    .replaceAll("XXX", '${_posItem.posData['name']}')));

            if (isConfirmed) {
              posItemProvider.setArchived(_posItem.id!);

              if (mounted) {
                showToast(
                    context,
                    StringUtil.localize(context)
                        .messsage_success_archive_dialog
                        .replaceAll("XXX", '${_posItem.posData['name']}'));
              }
              if (mounted) Navigator.pop(context);
            }
          },
          icon: const Icon(Icons.archive),
        ),
      ],
      child: StocklioScrollView(
        child: Center(
          child: Container(
            alignment: Alignment.topCenter,
            width: isDesktop
                ? Constants.largeScreenSize - Constants.navRailWidth * 2
                : null,
            child: Column(
              children: [
                TextField(
                  style: TextStyle(
                      color: AppTheme.instance.disabledTextFormFieldTextColor),
                  enabled: false,
                  controller: _nameController,
                  decoration: InputDecoration(
                    labelText: StringUtil.localize(context).label_name,
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  style: TextStyle(
                      color: AppTheme.instance.disabledTextFormFieldTextColor),
                  enabled: false,
                  controller: _articleGroupController,
                  decoration: InputDecoration(
                    labelText: StringUtil.localize(context).label_article_group,
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.next,
                ),
                const SizedBox(height: 16),
                TextField(
                  style: TextStyle(
                      color: AppTheme.instance.disabledTextFormFieldTextColor),
                  enabled: false,
                  controller: _sellingPriceController,
                  decoration: InputDecoration(
                    labelText: StringUtil.localize(context).label_selling_price,
                    alignLabelWithHint: true,
                  ),
                  textInputAction: TextInputAction.next,
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
                          Text('${StringUtil.localize(context).label_cost} %'),
                          Text(
                            '${itemCostPercent.toStringAsFixed(2)}%',
                            style: TextStyle(
                              color: _getCostPercentColor(itemCostPercent),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(width: 48),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(StringUtil.localize(context).label_total_cost),
                          Text(
                              '${StringUtil.formatNumber(numberFormat, POSButtonUtil.getTotalCost(_posItem, context))}${profileProvider.profile.currencyShort}'),
                        ],
                      ),
                      const SizedBox(width: 64),
                    ],
                  ),
                ),
                if (_posItem.items.entries.isEmpty)
                  Center(
                    child: Text(
                      StringUtil.localize(context).label_please_add_ingredients,
                      style: TextStyle(color: !isFormValid ? Colors.red : null),
                    ),
                  ),
                ..._posItem.items.entries.map(
                  (e) {
                    var item = context.read<ItemProvider>().findById(e.key);

                    if (item == null) {
                      var recipe =
                          context.read<RecipeProvider>().findById(e.key);
                      if (recipe != null) {
                        item ??= Item.fromRecipe(context, recipe);
                      }
                    }

                    if (item == null) return const SizedBox();

                    final itemUnit = item.unit;
                    final itemSize = item.size;
                    final ingredientCost = _posItem.items[e.key]! * item.cost;
                    final ingredientSize = _posItem.items[e.key]! * item.size!;

                    bool isInteger(num value) =>
                        value is int || value == value.roundToDouble();

                    final isIntegerIngredientSize = isInteger(ingredientSize);

                    final ingredientText =
                        '${item.name}, ${ParseUtil.toNum(item.size)}$itemUnit, ${StringUtil.formatNumber(numberFormat, item.cost)}${profileProvider.profile.currencyShort}';

                    return Container(
                      key: ValueKey(item.id),
                      margin: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          Expanded(
                            child: Stack(
                              children: [
                                Card(
                                  shape: RoundedRectangleBorder(
                                    side: BorderSide(
                                      color:
                                          Theme.of(context).colorScheme.primary,
                                      width: 2,
                                    ),
                                    borderRadius: BorderRadius.circular(4),
                                  ),
                                  margin: EdgeInsets.zero,
                                  color:
                                      Theme.of(context).colorScheme.background,
                                  child: Container(
                                    padding: const EdgeInsets.all(8),
                                    child: Row(
                                      children: [
                                        Expanded(
                                          child: ValueTextField(
                                            enabled: false,
                                            value: ingredientText,
                                            decoration: InputDecoration(
                                              labelText:
                                                  StringUtil.localize(context)
                                                      .label_ingredient,
                                              hintText:
                                                  StringUtil.localize(context)
                                                      .label_ingredient,
                                              alignLabelWithHint: true,
                                              isDense: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 4),
                                        SizedBox(
                                          width: 80,
                                          child: ValueTextField(
                                            textAlign: TextAlign.end,
                                            focusNode: _itemFocusNodes[e.key],
                                            value: _posItem.items[e.key]! != 0
                                                ? isIntegerIngredientSize
                                                    ? ingredientSize
                                                        .toStringAsFixed(0)
                                                    : ingredientSize
                                                        .toStringAsFixed(2)
                                                : '',
                                            decoration: InputDecoration(
                                              labelText:
                                                  StringUtil.localize(context)
                                                      .label_size,
                                              isDense: true,
                                              hintText:
                                                  StringUtil.localize(context)
                                                      .label_size,
                                              errorText: !isFormValid &&
                                                      _posItem.items[e.key] == 0
                                                  ? StringUtil.localize(context)
                                                      .label_enter_size
                                                  : null,
                                              suffix: Text(
                                                ' ${item.unit ?? ''}',
                                              ),
                                            ),
                                            inputFormatters: [
                                              DecimalInputFormatter(),
                                              LengthLimitingTextInputFormatter(
                                                  6),
                                            ],
                                            onChanged: (value) {
                                              value =
                                                  value.isEmpty ? '0' : value;
                                              setState(() {
                                                final items = {
                                                  ..._posItem.items
                                                };
                                                items[e.key] = ParseUtil.toNum(
                                                        value) /
                                                    ParseUtil.toNum(itemSize);
                                                _posItem = _posItem.copyWith(
                                                    items: items);
                                              });
                                            },
                                            keyboardType: const TextInputType
                                                .numberWithOptions(
                                              decimal: true,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        SizedBox(
                                          width: 80,
                                          child: Padding(
                                            padding: const EdgeInsets.only(
                                                left: 8.0),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              children: [
                                                Text(
                                                  StringUtil.localize(context)
                                                      .label_cost,
                                                  textAlign: TextAlign.left,
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: AppTheme.instance
                                                          .disabledTextFormFieldLabelColor),
                                                ),
                                                Text(
                                                  '${StringUtil.formatNumber(numberFormat, ingredientCost)}${profileProvider.profile.currencyShort}',
                                                ),
                                              ],
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Align(
                                          alignment: Alignment.topRight,
                                          child: IconButton(
                                            onPressed: () {
                                              final items = {..._posItem.items};

                                              items.remove(e.key);

                                              setState(() {
                                                _posItem = _posItem.copyWith(
                                                    items: items);
                                              });
                                            },
                                            icon: const Icon(Icons.delete),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
                Column(
                  children: [
                    TextField(
                      focusNode: _itemSearchFocusNode,
                      key: suggestionsKey,
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: StringUtil.localize(context)
                            .label_ingredient_search,
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
                                    posItemUIProvider.itemsQueryString = '';
                                  });
                                },
                              ),
                      ),
                      onChanged: (value) {
                        posItemUIProvider.itemsQueryString = value;
                        Scrollable.ensureVisible(
                          suggestionsKey.currentContext!,
                          duration: const Duration(milliseconds: 500),
                        );
                      },
                    ),
                    ...suggestions.map(
                      (item) {
                        final itemCost = StringUtil.formatNumber(
                          context.read<ProfileProvider>().profile.numberFormat,
                          item.cost,
                        );

                        var variety = '';
                        if (item.variety == 'Recipe') {
                          final dish =
                              recipeProvider.findDishById(item.itemId!);
                          variety = dish != null
                              ? StringUtil.localize(context).label_menu_item
                              : StringUtil.localize(context).label_prebatch;
                        }

                        return Container(
                          decoration: const BoxDecoration(
                            border: Border(
                              bottom:
                                  BorderSide(width: 2, color: Colors.white12),
                            ),
                          ),
                          child: SearchItem(
                            name: item.name ?? '',
                            cost: itemCost,
                            size: item.size.toString(),
                            unit: item.unit.toString(),
                            variety: item.variety == 'Recipe'
                                ? variety
                                : item.variety.toString(),
                            query: query,
                            onTap: () {
                              final items = {..._posItem.items};
                              items[item.id!] = 0;

                              setState(() {
                                _posItem = _posItem.copyWith(items: items);
                                _searchController.clear();
                              });

                              items.putIfAbsent(item.id!, () => 0);

                              _posItem = _posItem.copyWith(items: items);
                              posItemUIProvider.itemsQueryString = '';

                              // Add new focus node
                              _itemFocusNodes.putIfAbsent(
                                  item.id!, () => FocusNode());
                              _itemFocusNodes[item.id]!.requestFocus();
                            },
                          ),
                        );
                      },
                    ).toList(),
                    if (isCheckboxVisible) const SizedBox(height: 8),
                    if (isCheckboxVisible)
                      CheckboxListTile(
                        title: Text(StringUtil.localize(context)
                            .label_leave_item_unconnected),
                        value: isItemUnconnected,
                        onChanged: (value) {
                          setState(() {
                            isItemUnconnected = value ?? false;
                          });
                        },
                        activeColor: Theme.of(context).colorScheme.primary,
                        controlAffinity: ListTileControlAffinity.leading,
                      ),
                  ],
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: StockifiButton(
                    onPressed: () {
                      setState(() {
                        isFormValid = isItemUnconnected ||
                            (_posItem.items.isNotEmpty &&
                                !_posItem.items.values.contains(0));

                        if (isFormValid) {
                          savePOSItem();
                        }
                      });
                    },
                    child: Text(StringUtil.localize(context).label_submit),
                  ),
                ),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
