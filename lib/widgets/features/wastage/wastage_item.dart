import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/wastage_item.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/data/wastage_items.dart';
import 'package:stocklio_flutter/providers/ui/wastage_ui_provider.dart';
import 'package:stocklio_flutter/screens/in_progress_new.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/text_util.dart';
import 'package:stocklio_flutter/utils/wastage_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/page.dart';
import 'package:stocklio_flutter/widgets/common/search_item.dart';
import 'package:stocklio_flutter/widgets/features/wastage/add_wastage.dart';
import 'package:stocklio_flutter/widgets/features/wastage/wastage_body.dart';

class WastageItemListTile extends StatelessWidget {
  final Item item;
  final String wastageId;
  final String query;
  final bool isExpandedBySearch;
  final WastageItem? wastageItem;
  final bool isItemDeleted;

  const WastageItemListTile({
    Key? key,
    required this.wastageId,
    this.wastageItem,
    required this.item,
    this.query = '',
    this.isExpandedBySearch = false,
    this.isItemDeleted = false,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final wastageItem = context
        .read<WastageItemProvider>()
        .getWastageItemByItemId(wastageId, item.id!);

    final wastageUIProvider = context.read<WastageUIProvider>();
    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;

    final isExpanded = isExpandedBySearch ||
        (wastageItem != null &&
            (wastageItem.items ?? {}).isNotEmpty &&
            context
                .watch<WastageUIProvider>()
                .isWastageExpanded(wastageItem.id!));

    num totalCost = wastageItem == null
        ? 0
        : WastageUtil.getWastageTotal(wastageItem, item);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchItem(
          onTap: wastageItem != null && (wastageItem.items ?? {}).isNotEmpty
              ? () {
                  context
                      .read<WastageUIProvider>()
                      .toggleWastageExpanded(wastageItem.id!, !isExpanded);
                }
              : null,
          name: item.name ?? '',
          size: item.size.toString(),
          unit: item.unit.toString(),
          variety: item.variety.toString(),
          query: query,
          cost: StringUtil.formatNumber(
            context.read<ProfileProvider>().profile.numberFormat,
            wastageItem?.cost ?? 0,
          ),
          subtitle: LayoutBuilder(builder: (context, constraints) {
            return GestureDetector(
              onTap: () {
                if (TextUtil.hasTextOverflow(
                  item.name!,
                  style: Theme.of(context).textTheme.titleSmall!,
                  maxWidth: constraints.maxWidth,
                )) {
                  !wastageUIProvider.isPressed
                      ? StringUtil.showLongText(
                          context,
                          '${item.size}${item.unit ?? 'ml'}',
                          wastageUIProvider.setIsPressed,
                        )
                      : StringUtil.truncateLongText(
                          wastageUIProvider.setIsPressed);
                }
              },
              child: wastageUIProvider.isPressed
                  ? Text(
                      '${item.size}${item.unit ?? 'ml'}',
                    )
                  : Text(
                      '${item.size}${item.unit ?? 'ml'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            );
          }),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                StringUtil.formatNumber(numberFormat, totalCost),
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                ),
              ),
              GestureDetector(
                onTap: isItemDeleted
                    ? () {
                        showToast(
                            context,
                            StringUtil.localize(context)
                                .message_unable_to_waste_deleted_item);
                      }
                    : null,
                child: IconButton(
                  icon: const Icon(Icons.add_box_outlined),
                  onPressed: isItemDeleted
                      ? null
                      : () {
                          // TODO: Create another route in go_router.dart similar to Edit Item
                          Navigator.of(context, rootNavigator: true).push(
                            InProgressRoute(
                              fullscreenDialog: true,
                              builder: (context) {
                                return StocklioModal(
                                  title: StringUtil.localize(context)
                                      .label_add_wastage,
                                  resizeToAvoidBottomInset: false,
                                  child: AddWastage(
                                    item: item,
                                    wastageItem: wastageItem,
                                    wastageId: wastageId,
                                  ),
                                );
                              },
                            ),
                          );
                        },
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
              IconButton(
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                color: Theme.of(context).colorScheme.primary,
                onPressed: wastageItem != null &&
                        (wastageItem.items ?? {}).isNotEmpty
                    ? () {
                        context.read<WastageUIProvider>().toggleWastageExpanded(
                            wastageItem.id!, !isExpanded);
                      }
                    : null,
              ),
            ],
          ),
        ),
        if (wastageItem != null && isExpanded)
          WastageItemBody(
            wastageItem: wastageItem,
            wastageId: wastageId,
          ),
      ],
    );
  }
}
