import 'package:flutter/material.dart';
import 'package:fuzzy/fuzzy.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/ui/count_item_view_ui_provider.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/modal_bottom_sheet.dart';
import 'package:stocklio_flutter/widgets/common/search_text_field.dart';

class CountFilterModal extends StatefulWidget {
  const CountFilterModal({super.key});

  @override
  State<CountFilterModal> createState() => _CountFilterModalState();
}

class _CountFilterModalState extends State<CountFilterModal> {
  late TextEditingController _searchController;
  String _query = "";
  void _clearAllFilters(BuildContext context) {
    context.read<CountItemViewUIProvider>().clearItemsTypeFilters();
    context.read<CountItemViewUIProvider>().clearItemsVarietyFilters();
  }

  void _toggleType(BuildContext context, String type, bool? value) {
    context.read<CountItemViewUIProvider>().toggleItemsTypeFilter(type);
  }

  void _toggleVariety(BuildContext context, String variety, bool? value) {
    context.read<CountItemViewUIProvider>().toggleItemsVarietyFilter(variety);
  }

  @override
  void initState() {
    _searchController = TextEditingController();
    super.initState();
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final countItemViewUIProvider = context.watch<CountItemViewUIProvider>();
    final itemProvider = context.watch<ItemProvider>();
    final recipeProvider = context.read<RecipeProvider>();
    List<String> typeFilters = countItemViewUIProvider.itemsTypeFilters;

    List<String> varietyFilters = countItemViewUIProvider.itemsVarietyFilters;

    final typesWithVarieties = {
      ...itemProvider.types,
      ...recipeProvider.types,
    };

    final typesFuse = Fuzzy<String>(typesWithVarieties.keys.toList(),
        options: FuzzyOptions(
          keys: [
            WeightedKey(
              name: 'variety',
              getter: (String x) => x,
              weight: 0.8,
            )
          ],
        ));
    final varietiesFuse = Fuzzy<String>(
        [
          ...itemProvider.allVarieties,
          ...recipeProvider.allVarieties,
        ]
            .where((element) => element.toLowerCase() != "menu item")
            .toSet()
            .toList(),
        options: FuzzyOptions(
          keys: [
            WeightedKey(
              name: 'filter',
              getter: (String x) => x,
              weight: 0.8,
            )
          ],
        ));
    var types = typesFuse.search(_query).map((e) => e.item).toList();
    var varieties = varietiesFuse.search(_query).map((e) => e.item).toList();
    if (_query.isEmpty) {
      types.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
      varieties.sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));
    }

    return StocklioModalBottomSheet(
      label: 'Filters',
      actions: [
        TextButton(
          onPressed: () => _clearAllFilters(context),
          child: Text(StringUtil.localize(context).label_clear),
        ),
      ],
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SearchTextField(
            controller: _searchController,
            onChanged: (value) {
              setState(() {
                _query = value.toLowerCase();
              });
            },
            hintText: "Search ${StringUtil.localize(context).label_filters}...",
            clearCallback: () {
              setState(() {
                _searchController.clear();
                _query = '';
              });
            },
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            StringUtil.localize(context).label_types,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (types.isEmpty)
          Center(child: Text("Type $_query not found"))
        else
          ...types.map(
            (e) {
              return CheckboxListTile(
                value: typeFilters.contains(e),
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(e),
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool? value) {
                  _toggleType(context, e, value);
                },
              );
            },
          ).toList(),
        Padding(
          padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16.0),
          child: Text(
            StringUtil.localize(context).label_varieties,
            style: Theme.of(context)
                .textTheme
                .titleMedium
                ?.copyWith(fontWeight: FontWeight.bold),
          ),
        ),
        if (varieties.isEmpty)
          Center(child: Text("Variety $_query not found"))
        else
          ...varieties.map(
            (e) {
              return CheckboxListTile(
                value: varietyFilters.contains(e),
                controlAffinity: ListTileControlAffinity.trailing,
                title: Text(e),
                activeColor: Theme.of(context).colorScheme.primary,
                onChanged: (bool? value) {
                  _toggleVariety(context, e, value);
                },
              );
            },
          ).toList(),
      ],
    );
  }
}
