import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/wastage_item.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/data/wastage_items.dart';
import 'package:stocklio_flutter/providers/ui/wastage_ui_provider.dart';
import 'package:stocklio_flutter/screens/in_progress_new.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/text_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import 'package:stocklio_flutter/widgets/common/page.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/features/wastage/add_wastage.dart';

import '../../../utils/string_util.dart';
import '../recipes/recipe_header.dart';

class WastageItemBody extends StatelessWidget {
  final WastageItem wastageItem;
  final String ingredientQuery;
  final String wastageId;

  const WastageItemBody({
    Key? key,
    required this.wastageItem,
    this.ingredientQuery = '',
    required this.wastageId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.read<ItemProvider>();
    final profile = context.read<ProfileProvider>().profile;
    final isItemCutAwayEnabled = profile.isItemCutawayEnabled;
    final numberFormat = profile.numberFormat;
    var item = itemProvider.findById(wastageItem.itemId);
    var isConfirmed = false;
    if (item == null) {
      var recipe = context.read<RecipeProvider>().findById(wastageItem.itemId);
      if (recipe != null) {
        item ??= Item.fromRecipe(context, recipe);
      }
    }

    final sortedMap = Map.fromEntries((wastageItem.items ?? {}).entries.toList()
      ..sort((e1, e2) => e2.value.compareTo(e1.value)));
    final itemsList = sortedMap.entries.toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          const ItemsHeader(
            trailing: Padding(
              padding: EdgeInsets.all(8.0),
              child: SizedBox(width: 16),
            ),
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: itemsList.length,
            itemBuilder: (context, index) {
              num partSize;
              double cost;

              if (item == null) {
                return const SizedBox();
              }

              partSize =
                  ParseUtil.toNum(itemsList[index].value) * (item.size ?? 0);
              num cutaway = 1;
              if (isItemCutAwayEnabled) {
                cutaway = item.cutaway + 1;
              }
              logger.d(cutaway);
              cost = ParseUtil.toDouble(itemsList[index].value) *
                  item.cost *
                  cutaway;

              var wastageItemUIProvider = context.watch<WastageUIProvider>();

              return Container(
                color: index.isEven ? AppTheme.instance.rowColor : null,
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTap: () {
                              if (TextUtil.hasTextOverflow(
                                item!.name!,
                                maxWidth: constraints.maxWidth,
                                totalHorizontalPadding: 16,
                              )) {
                                !wastageItemUIProvider.isPressed
                                    ? StringUtil.showLongText(
                                        context,
                                        item.name!,
                                        wastageItemUIProvider.setIsPressed,
                                      )
                                    : StringUtil.truncateLongText(
                                        wastageItemUIProvider.setIsPressed,
                                      );
                              }
                            },
                            child: wastageItemUIProvider.isPressed
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          ...TextUtil.highlightSearchText(
                                              context,
                                              item!.name!,
                                              ingredientQuery),
                                        ],
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                    ),
                                  )
                                : Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          ...TextUtil.highlightSearchText(
                                              context,
                                              item!.name!,
                                              ingredientQuery),
                                        ],
                                        style: const TextStyle(
                                            color: Colors.white),
                                      ),
                                      maxLines: 1,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                  ),
                          );
                        },
                      ),
                    ),
                    Expanded(
                      flex: !Responsive.isMobile(context) ? 2 : 4,
                      child: PaddedText(
                        '${StringUtil.formatNumber(numberFormat, partSize)}${item.unit}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isItemCutAwayEnabled)
                      Expanded(
                        flex: !Responsive.isMobile(context) ? 2 : 4,
                        child: PaddedText(
                          StringUtil.toPercentage(item.cutaway),
                          textAlign: TextAlign.right,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    Expanded(
                      flex: !Responsive.isMobile(context) ? 2 : 4,
                      child: PaddedText(
                        StringUtil.formatNumber(numberFormat, cost),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: InkWell(
                        onTap: () {
                          // TODO: Create another route in go_router.dart similar to Edit Item
                          Navigator.of(context, rootNavigator: true).push(
                            InProgressRoute(
                              fullscreenDialog: true,
                              builder: (context) {
                                final wastageItemProvider =
                                    context.read<WastageItemProvider>();
                                return StocklioModal(
                                  title: StringUtil.localize(context)
                                      .label_edit_wastage,
                                  actions: [
                                    IconButton(
                                      onPressed: () async {
                                        isConfirmed = await confirm(
                                          context,
                                          RichText(
                                            text: TextSpan(
                                              children: <TextSpan>[
                                                TextSpan(
                                                  text: StringUtil.localize(
                                                          context)
                                                      .message_confirm_remove_wastages
                                                      .replaceAll("XXX",
                                                          '${item!.name}'),
                                                  style: Theme.of(context)
                                                      .textTheme
                                                      .titleLarge,
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                        if (isConfirmed) {
                                          var tempWastageItem =
                                              Map.of(wastageItem.items!);
                                          tempWastageItem.removeWhere(
                                              (key, value) =>
                                                  key == itemsList[index].key);

                                          await wastageItemProvider
                                              .updateWastageItem(
                                                  wastageItem.copyWith(
                                                      items: tempWastageItem))
                                              .whenComplete(
                                                  () => Navigator.pop(context));
                                        }
                                      },
                                      icon: Icon(
                                        Icons.delete_outline,
                                        color: Theme.of(context)
                                            .colorScheme
                                            .primary,
                                        size: 20,
                                      ),
                                    )
                                  ],
                                  resizeToAvoidBottomInset: false,
                                  child: AddWastage(
                                    item: item!,
                                    wastageItem: wastageItem,
                                    wastageItemEntryId: itemsList[index].key,
                                    wastageItemEntrySize:
                                        itemsList[index].value * item.size!,
                                    wastageId: wastageId,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                        child: Icon(
                          Icons.edit,
                          size: 16,
                          color: Theme.of(context).colorScheme.primary,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
