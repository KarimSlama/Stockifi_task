import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/pos_item_ui.dart';
import 'package:stocklio_flutter/utils/extensions.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/search_item.dart';
import 'pos_item_body.dart';

class POSItemListTile extends StatefulWidget {
  final PosItem posItem;
  final String query;
  final int index;
  final bool isExpandedBySearch;

  const POSItemListTile({
    Key? key,
    required this.posItem,
    this.query = '',
    this.index = 0,
    this.isExpandedBySearch = false,
  }) : super(key: key);

  @override
  State<POSItemListTile> createState() => _POSItemListTileState();
}

class _POSItemListTileState extends State<POSItemListTile> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>()..profile;
    final isExpanded = widget.isExpandedBySearch ||
        context
            .watch<POSItemUIProvider>()
            .isPOSItemExpanded(widget.posItem.id!);

    final itemName = widget.posItem.posData['name'];
    final itemPrice = ParseUtil.toNum(
        double.parse(widget.posItem.posData['price'].toString())
            .toPrecision(2));

    final itemCostPercent = context
        .read<ItemProvider>()
        .getPOSItemCostPercent(widget.posItem, context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchItem(
          name: '$itemName, $itemPrice${profileProvider.profile.currencyShort}',
          query: widget.query,
          subtitle: const SizedBox(),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('${itemCostPercent.toStringAsFixed(2)}%'),
              widget.posItem.archived
                  ? IconButton(
                      onPressed: () async {
                        final isConfirmed = await confirm(
                            context,
                            Text(StringUtil.localize(context)
                                .message_confirm_remove_pos_button_archives
                                .replaceAll("XXX",
                                    ('${widget.posItem.posData['name']}'))));

                        if (isConfirmed) {
                          if (!mounted) return;
                          context
                              .read<PosItemProvider>()
                              .unarchivePOSItem(widget.posItem.id!);

                          showToast(
                              context,
                              StringUtil.localize(context)
                                  .message_success_remove_item_archives
                                  .replaceAll("XXX",
                                      '${widget.posItem.posData['name']}'));
                        }
                      },
                      icon: const Icon(Icons.archive),
                      color: Theme.of(context).colorScheme.primary,
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit),
                      color: Theme.of(context).colorScheme.primary,
                      onPressed: () {
                        final isAdmin = context.read<AuthProvider>().isAdmin;
                        final profile = context.read<ProfileProvider>().profile;
                        if (isAdmin) {
                          context.go(
                              '/admin/lists/posbuttons/edit-pos-item/${widget.posItem.id}?selectedProfileId=${profile.id}');
                        } else {
                          context.go(
                              '/lists/posbuttons/edit-pos-item/${widget.posItem.id}');
                        }
                      },
                    ),
              IconButton(
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                color: Theme.of(context).colorScheme.primary,
                onPressed: widget.posItem.items.isNotEmpty
                    ? () {
                        context.read<POSItemUIProvider>().togglePOSItemExpanded(
                            widget.posItem.id!, !isExpanded);
                      }
                    : null,
              ),
            ],
          ),
        ),
        Visibility(
          visible: isExpanded && (widget.posItem.items.isNotEmpty),
          child: POSItemBody(
            posItem: widget.posItem,
            ingredientQuery: widget.query,
          ),
        ),
      ],
    );
  }
}
