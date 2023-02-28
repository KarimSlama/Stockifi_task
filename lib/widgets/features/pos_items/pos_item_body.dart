import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/ui/pos_item_ui.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/pos_button_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import '../../../providers/data/users.dart';
import '../../../utils/app_theme_util.dart';
import '../../../utils/string_util.dart';
import '../../../utils/text_util.dart';
import '../../common/padded_text.dart';
import '../../common/responsive.dart';
import '../recipes/recipe_header.dart';

class POSItemBody extends StatelessWidget {
  const POSItemBody({
    Key? key,
    required this.posItem,
    this.ingredientQuery = '',
  }) : super(key: key);

  final PosItem posItem;
  final String ingredientQuery;

  void showLongText(
    BuildContext context,
    String text,
  ) {
    final posItemUIProvider = context.read<POSItemUIProvider>();
    posItemUIProvider.setIsPressed(true);
    showToast(context, text);
  }

  void truncateLongText(BuildContext context) {
    final posItemUIProvider = context.read<POSItemUIProvider>();
    posItemUIProvider.setIsPressed(false);
  }

  @override
  Widget build(BuildContext context) {
    final profile = context.read<ProfileProvider>().profile;
    final numberFormat = profile.numberFormat;
    final posItemUIProvider = context.watch<POSItemUIProvider>();
    var isPressed = posItemUIProvider.isPressed;
    final isItemCutAway = profile.isItemCutawayEnabled;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          const ItemsHeader(),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: posItem.items.keys.length + 1,
            itemBuilder: (context, index) {
              if (index == posItem.items.keys.length) {
                final totalCost = POSButtonUtil.getTotalCost(posItem, context);

                return Container(
                  color: index.isEven ? AppTheme.instance.rowColor : null,
                  child: PaddedText(
                    StringUtil.formatNumber(numberFormat, totalCost),
                    textAlign: TextAlign.right,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                );
              }

              final itemId = posItem.items.keys.toList()[index];
              var item = context.read<ItemProvider>().findById(itemId);

              if (item == null) {
                var recipe = context.read<RecipeProvider>().findById(itemId);
                if (recipe != null) {
                  item ??= Item.fromRecipe(context, recipe);
                }
              }

              if (item == null) return const SizedBox();

              final ingredientSize =
                  ParseUtil.toNum(posItem.items[itemId] ?? 0) *
                      (item.size ?? 0);
              final ingredientCost =
                  ParseUtil.toNum(posItem.items[itemId] ?? 0) * item.cost;

              final itemNameSizeUnit =
                  '${item.name}, ${item.size ?? 0}${item.unit}';

              return Container(
                color: index.isEven ? AppTheme.instance.rowColor : null,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTap: () {
                              if (TextUtil.hasTextOverflow(
                                itemNameSizeUnit,
                                maxWidth: constraints.maxWidth,
                                totalHorizontalPadding: 16,
                              )) {
                                isPressed
                                    ? truncateLongText(context)
                                    : showLongText(context, itemNameSizeUnit);
                              }
                            },
                            child: isPressed
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          ...TextUtil.highlightSearchText(
                                              context,
                                              '${item!.name}',
                                              ingredientQuery),
                                          ...TextUtil.highlightSearchText(
                                              context,
                                              '${item.size ?? 0}',
                                              ingredientQuery),
                                          TextSpan(text: item.unit),
                                          ...TextUtil.highlightSearchText(
                                            context,
                                            '(${item.variety})',
                                            ingredientQuery,
                                          ),
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
                                              itemNameSizeUnit,
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
                        '$ingredientSize${item.unit}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isItemCutAway)
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
                        StringUtil.formatNumber(numberFormat, ingredientCost),
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
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
