import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/models/report_item.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/stocklio_scrollview.dart';
import 'type_items_list.dart';

class CountItemsList extends StatefulWidget {
  const CountItemsList({
    Key? key,
    required this.items,
    required this.showLocator,
  }) : super(key: key);

  final List<ReportItem> items;
  final bool showLocator;

  @override
  State<CountItemsList> createState() => _CountItemsListState();
}

class _CountItemsListState extends State<CountItemsList> {
  final _xAxisScrollController = ScrollController();

  @override
  void dispose() {
    _xAxisScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // TODO: Improve performance
    return Responsive.isMobile(context)
        ? NotificationListener<ScrollNotification>(
            onNotification: (_) {
              return true;
            },
            child: StocklioScrollView(
              key: const PageStorageKey<String>('horizontalScrollController'),
              showScrollbarOnTopAndBottom: true,
              controller: _xAxisScrollController,
              scrollDirection: Axis.horizontal,
              child: Container(
                padding: const EdgeInsets.only(top: 12.0),
                width: MediaQuery.of(context).size.width,
                child: CountItemsListContent(
                  reportItems: widget.items,
                  showLocator: widget.showLocator,
                ),
              ),
            ),
          )
        : Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: CountItemsListContent(
              reportItems: widget.items,
              showLocator: widget.showLocator,
            ),
          );
  }
}

class CountItemsListContent extends StatelessWidget {
  final List<ReportItem> reportItems;
  final bool showLocator;
  const CountItemsListContent({
    Key? key,
    required this.reportItems,
    required this.showLocator,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final sortReport = context.read<ProfileProvider>().profile.sortReport;
    final mapOfItems = getMapOfItems(reportItems, sortReport);
    var grandTotal = 0.0;
    final numberFormat = context.read<ProfileProvider>().profile.numberFormat;

    final sortedKeys = mapOfItems.keys.toList();
    sortedKeys.sort((x, y) => x.compareTo(y));
    return SizedBox(
      width: MediaQuery.of(context).size.width + 100,
      child: Column(
        children: [
          CountItemsListHeader(
            showLocator: showLocator,
          ),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: mapOfItems.keys.length + 2,
            itemBuilder: (context, index) {
              if (index == mapOfItems.keys.length) {
                for (var item in reportItems) {
                  grandTotal += item.quantity! * item.cost!;
                }

                return Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: PaddedText(
                        StringUtil.localize(context).label_grand_total,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
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
                          StringUtil.formatNumber(numberFormat, grandTotal),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
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
                );
              } else if (index == mapOfItems.keys.length + 1) {
                return const SizedBox(
                  height: 68,
                );
              }

              final key = sortedKeys[index];

              return TypeItemsList(
                type: key,
                items: mapOfItems[key]!,
                showLocator: showLocator,
              );
            },
          ),
        ],
      ),
    );
  }
}

class CountItemsListHeader extends StatelessWidget {
  const CountItemsListHeader({
    Key? key,
    required this.showLocator,
  }) : super(key: key);

  final bool showLocator;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: MediaQuery.of(context).size.width + 100,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Container(),
            ),
          ),
          Expanded(
            flex: !Responsive.isMobile(context) ? 2 : 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                StringUtil.localize(context).label_on_hand,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          const SizedBox(width: 4),
          Expanded(
            flex: !Responsive.isMobile(context) ? 2 : 4,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8.0),
              child: Text(
                StringUtil.localize(context).label_cost,
                textAlign: TextAlign.right,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
          ),
          if (showLocator) const SizedBox(width: 4),
          if (showLocator)
            Expanded(
              flex: !Responsive.isMobile(context) ? 2 : 4,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 8.0),
                child: Text(
                  'Locate Item',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

Map<String, List<ReportItem>> getMapOfItems(
  List<ReportItem> items,
  String sortReport,
) {
  var map = <String, List<ReportItem>>{};

  for (var item in items) {
    dynamic key;

    switch (sortReport) {
      case 'type':
        key = item.type;
        break;
      case 'variety':
        key = item.variety;
        break;
      case 'area':
        key = item.areaName;
        break;
      default:
    }

    if (map.containsKey(key)) {
      map[key]!.add(item);
    } else {
      map.putIfAbsent(key!, () => [item]);
    }
  }

  return map;
}
