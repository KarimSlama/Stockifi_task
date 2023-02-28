import 'package:flutter/material.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/filter_enums.dart';
import 'package:stocklio_flutter/widgets/common/modal_bottom_sheet.dart';
import 'package:stocklio_flutter/widgets/common/show_archived_widget.dart';
import '../../../providers/data/items.dart';
import 'package:provider/provider.dart';

class ItemFilters extends StatelessWidget {
  final FilterSetting filterSetting;

  const ItemFilters({Key? key, required this.filterSetting}) : super(key: key);

  void _toggleType(BuildContext context, String type, bool? value) {
    final itemProvider = context.read<ItemProvider>();

    if (filterSetting == FilterSetting.items) {
      itemProvider.toggleItemsTypeFilter(type);
    } else if (filterSetting == FilterSetting.inventory) {
      itemProvider.toggleInventoryTypeFilter(type);
    }
  }

  void _toggleVariety(BuildContext context, String variety, bool? value) {
    final itemProvider = context.read<ItemProvider>();

    if (filterSetting == FilterSetting.items) {
      itemProvider.toggleItemsVarietyFilter(variety);
    } else if (filterSetting == FilterSetting.inventory) {
      itemProvider.toggleInventoryVarietyFilter(variety);
    }
  }

  void _clearTypeFilters(BuildContext context) {
    final itemProvider = context.read<ItemProvider>();

    if (filterSetting == FilterSetting.items) {
      itemProvider.clearItemsTypeFilters();
    } else if (filterSetting == FilterSetting.inventory) {
      itemProvider.clearInventoryTypeFilters();
    }
  }

  void _clearVarietyFilters(BuildContext context) {
    final itemProvider = context.read<ItemProvider>();

    if (filterSetting == FilterSetting.items) {
      itemProvider.clearItemsVarietyFilters();
    } else if (filterSetting == FilterSetting.inventory) {
      itemProvider.clearInventoryVarietyFilters();
    }
  }

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final typesWithVarieties = itemProvider.types;
    final types = typesWithVarieties.keys;
    final varieties = itemProvider.allVarieties;

    List<String> typeFilters = [];
    List<String> varietyFilters = [];

    if (filterSetting == FilterSetting.items) {
      typeFilters = itemProvider.itemsTypeFilters;
      varietyFilters = itemProvider.itemsVarietyFilters;
    } else if (filterSetting == FilterSetting.inventory) {
      typeFilters = itemProvider.inventoryTypeFilters;
      varietyFilters = itemProvider.inventoryVarietyFilters;
    }

    final showArchived = itemProvider.showArchived;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 16),
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            ShowArchivedChip(
                showArchived: showArchived,
                onTap: () => itemProvider.toggleShowArchived()),
            const SizedBox(width: 4),
            FilterChip(
              shape: typeFilters.isNotEmpty
                  ? StadiumBorder(
                      side: BorderSide(
                          color:
                              AppTheme.instance.themeData.colorScheme.primary))
                  : null,
              padding:
                  const EdgeInsets.only(top: 4, left: 4, bottom: 4, right: -4),
              showCheckmark: false,
              selected: typeFilters.isNotEmpty,
              onSelected: (value) {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    final itemProvider = context.watch<ItemProvider>();

                    List<String> typeFilters = [];

                    if (filterSetting == FilterSetting.items) {
                      typeFilters = itemProvider.itemsTypeFilters;
                    } else if (filterSetting == FilterSetting.inventory) {
                      typeFilters = itemProvider.inventoryTypeFilters;
                    }

                    return StocklioModalBottomSheet(
                      label: StringUtil.localize(context).label_types,
                      actions: [
                        TextButton(
                          onPressed: () => _clearTypeFilters(context),
                          child: Text(StringUtil.localize(context).label_clear),
                        ),
                      ],
                      children: [
                        ...types.map(
                          (e) {
                            return CheckboxListTile(
                              value: typeFilters.contains(e),
                              controlAffinity: ListTileControlAffinity.trailing,
                              title: Text(e),
                              activeColor:
                                  Theme.of(context).colorScheme.primary,
                              onChanged: (bool? value) {
                                _toggleType(context, e, value);
                              },
                            );
                          },
                        ).toList(),
                      ],
                    );
                  },
                );
              },
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(StringUtil.localize(context).label_type),
                  if (typeFilters.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 50),
                      child: Container(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          typeFilters.first,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  if (typeFilters.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('+${typeFilters.length - 1}'),
                    ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
            const SizedBox(width: 4),
            FilterChip(
              shape: varietyFilters.isNotEmpty
                  ? StadiumBorder(
                      side: BorderSide(
                          color:
                              AppTheme.instance.themeData.colorScheme.primary))
                  : null,
              padding:
                  const EdgeInsets.only(top: 4, left: 4, bottom: 4, right: -4),
              showCheckmark: false,
              selected: varietyFilters.isNotEmpty,
              onSelected: (value) {
                showModalBottomSheet(
                  context: context,
                  builder: (context) {
                    final itemProvider = context.watch<ItemProvider>();
                    List<String> varietyFilters = [];

                    if (filterSetting == FilterSetting.items) {
                      varietyFilters = itemProvider.itemsVarietyFilters;
                    } else if (filterSetting == FilterSetting.inventory) {
                      varietyFilters = itemProvider.inventoryVarietyFilters;
                    }

                    return StocklioModalBottomSheet(
                      label: StringUtil.localize(context).label_varieties,
                      actions: [
                        TextButton(
                          onPressed: () => _clearVarietyFilters(context),
                          child: Text(StringUtil.localize(context).label_clear),
                        ),
                      ],
                      children: [
                        ...varieties
                            .map(
                              (e) => CheckboxListTile(
                                value: varietyFilters.contains(e),
                                controlAffinity:
                                    ListTileControlAffinity.trailing,
                                title: Text(e),
                                activeColor:
                                    Theme.of(context).colorScheme.primary,
                                onChanged: (bool? value) {
                                  _toggleVariety(context, e, value);
                                },
                              ),
                            )
                            .toList(),
                      ],
                    );
                  },
                );
              },
              label: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(StringUtil.localize(context).label_varieties),
                  if (varietyFilters.isNotEmpty)
                    ConstrainedBox(
                      constraints: const BoxConstraints(maxWidth: 50),
                      child: Container(
                        padding: const EdgeInsets.only(left: 4),
                        child: Text(
                          varietyFilters.first,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ),
                  if (varietyFilters.length > 1)
                    Padding(
                      padding: const EdgeInsets.only(left: 4),
                      child: Text('+${varietyFilters.length - 1}'),
                    ),
                  const Icon(Icons.arrow_drop_down),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
