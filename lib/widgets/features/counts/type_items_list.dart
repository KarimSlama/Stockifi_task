import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/report_item.dart';
import 'package:stocklio_flutter/providers/ui/report_items_expanded.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:go_router/go_router.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

class TypeItemsList extends StatefulWidget {
  const TypeItemsList({
    Key? key,
    required this.type,
    required this.items,
    required this.showLocator,
  }) : super(key: key);

  final List<ReportItem> items;
  final String type;
  final bool showLocator;

  @override
  State<TypeItemsList> createState() => _TypeItemsListState();
}

class _TypeItemsListState extends State<TypeItemsList> {
  final _scrollController = ScrollController();

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    var reportItemExpandedProvider =
        context.watch<ReportItemExpandedProvider>();
    reportItemExpandedProvider.setExpandedReportItems(widget.items);

    void showLongText(ReportItem item, bool isExpanded) {
      reportItemExpandedProvider.toggleReportItemExpanded(item.id!, isExpanded);
      if (isExpanded) {
        showToast(context, '${item.name}');
      }
    }

    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;
    var typeSubTotal = 0.0;

    widget.items.sort((x, y) {
      final nameX = x.name ?? '';
      final nameY = y.name ?? '';
      return nameX.compareTo(nameY);
    });

    return ListView.builder(
      physics: const NeverScrollableScrollPhysics(),
      shrinkWrap: true,
      controller: _scrollController,
      itemCount: widget.items.length + 1,
      itemBuilder: (context, index) {
        // Display Type Subtotal
        if (index == widget.items.length) {
          return Container(
            color: index.isEven ? AppTheme.instance.rowColor : null,
            child: Row(
              children: [
                Expanded(
                  flex: 6,
                  child: PaddedText(
                    '${widget.type} ${StringUtil.localize(context).label_total}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
                ),

                ///placeholder for alignment
                Expanded(
                  flex: !Responsive.isMobile(context) ? 2 : 4,
                  child: const SizedBox.shrink(),
                ),
                const SizedBox(width: 4),
                Expanded(
                  flex: !Responsive.isMobile(context) ? 2 : 4,
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: PaddedText(
                      StringUtil.formatNumber(numberFormat, typeSubTotal),
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ),
                ),
                const SizedBox(width: 4),

                ///placeholder for alignment
                Expanded(
                  flex: !Responsive.isMobile(context) ? 2 : 4,
                  child: const SizedBox.shrink(),
                ),
              ],
            ),
          );
        }

        // Display Item
        final item = widget.items[index];
        final type = widget.type;
        final quantity = item.quantity!.toStringAsFixed(2);
        final itemTotal = item.quantity! * item.cost!;

        typeSubTotal += itemTotal;
        var isExpanded =
            reportItemExpandedProvider.getReportItemExpanded(item.id!) ?? false;

        final row = Container(
          color: index.isEven ? AppTheme.instance.rowColor : null,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Expanded(
                flex: 6,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    GestureDetector(
                      onTap: () {
                        showLongText(item, !isExpanded);
                      },
                      child: isExpanded
                          ? PaddedText(
                              '${item.name}',
                            )
                          : PaddedText(
                              '${item.name}',
                              overflow: TextOverflow.ellipsis,
                              maxLines: 1,
                            ),
                    ),
                    if (itemTotal >= 25000)
                      Padding(
                        padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                        child: Text(
                          StringUtil.localize(context).label_is_this_correct,
                          style: const TextStyle(
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              Expanded(
                flex: !Responsive.isMobile(context) ? 2 : 4,
                child: PaddedText(
                  quantity,
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              const SizedBox(width: 4),
              Expanded(
                flex: !Responsive.isMobile(context) ? 2 : 4,
                child: PaddedText(
                  StringUtil.formatNumber(numberFormat, itemTotal),
                  textAlign: TextAlign.right,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                ),
              ),
              if (widget.showLocator) const SizedBox(width: 4),
              if (widget.showLocator)
                Expanded(
                  flex: !Responsive.isMobile(context) ? 2 : 4,
                  child: IconButton(
                    onPressed: () async {
                      StringUtil.localize(context).label_ok;
                      final locate = await confirm(
                          context,
                          Text(
                              '${StringUtil.localize(context).message_locate_item_1} ${item.name} ${StringUtil.localize(context).message_locate_item_2}'));
                      if (locate) {
                        if (mounted) {
                          context.go('/current-count/locate/${item.name}');
                        }
                      }
                    },
                    icon: Icon(
                      Icons.my_location_rounded,
                      color: AppTheme.instance.themeData.colorScheme.primary,
                    ),
                  ),
                ),
            ],
          ),
        );

        var showTitle = false;

        switch (type) {
          case 'type':
            showTitle = widget.items[index - 1].type != type;
            break;
          case 'variety':
            showTitle = widget.items[index - 1].variety != type;
            break;
          case 'area':
            showTitle = widget.items[index - 1].areaName != type;
            break;
          default:
        }

        if (index == 0 || showTitle) {
          final typeText = PaddedText(
            widget.type,
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          );
          return Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              typeText,
              row,
            ],
          );
        }

        return row;
      },
    );
  }
}
