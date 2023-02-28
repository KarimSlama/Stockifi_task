import 'package:cloud_functions/cloud_functions.dart';
import 'package:flutter/material.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/count_item_search_button.dart';
import 'package:stocklio_flutter/widgets/common/filter_enums.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/search_text_field.dart';
import 'package:stocklio_flutter/widgets/shimmer/item_shimmer.dart';
import '../widgets/common/filters.dart';
import '../widgets/features/inventory/inventory_list_tile.dart';
import '../../../providers/data/items.dart';
import 'package:provider/provider.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({Key? key}) : super(key: key);

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  final _textController = TextEditingController();
  final _scrollController = ScrollController();

  String _query = '';

  @override
  void initState() {
    final itemProvider = context.read<ItemProvider>();
    _textController.text = itemProvider.queryString;
    _query = itemProvider.queryString;
    super.initState();
  }

  @override
  void dispose() {
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final accessLevel = profileProvider.profile.accessLevel;
    if (accessLevel < 3) {
      const textStyle = TextStyle(
        fontSize: 22,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      );
      return Center(
        child: Responsive.isMobile(context)
            ? Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    StringUtil.localize(context).text_upgrade1,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    StringUtil.localize(context).text_upgrade2,
                    textAlign: TextAlign.center,
                    style: textStyle,
                  ),
                ],
              )
            : Text(
                '${StringUtil.localize(context).text_upgrade1} ${StringUtil.localize(context).text_upgrade2}',
                textAlign: TextAlign.center,
                style: textStyle,
              ),
      );
    }

    final itemProvider = context.watch<ItemProvider>()..getItems();
    final posItemProvider = context.watch<PosItemProvider>()..posItems;
    final recipeProvider = context.watch<RecipeProvider>()..recipes;

    if (itemProvider.isLoadingItems ||
        posItemProvider.isLoading ||
        recipeProvider.isLoading) {
      return const ItemShimmer();
    }

    final results = itemProvider.search(
      _query,
      filterSetting: FilterSetting.inventory,
    );

    if (_query.isEmpty) {
      results.sort((x, y) {
        final nameDiff = x.name!.compareTo(y.name!);
        final costDiff = x.cost.compareTo(y.cost);
        if (x.cost == 0 || y.cost == 0) {
          return costDiff != 0 ? costDiff : nameDiff;
        }
        return nameDiff;
      });
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              InventoryTile(
                title: StringUtil.localize(context).label_last_fetch,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      'Sales: ${StringUtil.formatDate(profileProvider.profile.lastPOSFetch)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'Invoices: ${StringUtil.formatDate(profileProvider.profile.lastAPFetch)}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              InventoryTile(
                title: StringUtil.localize(context).nav_label_invoices,
                child: FutureBuilder(
                  future: FirebaseFunctions.instance
                      .httpsCallable('users-getInvoicePeriodCount')
                      .call(
                    {
                      'userId': profileProvider.profile.id,
                    },
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        try {
                          final result = snapshot.data as HttpsCallableResult;
                          final data = result.data;
                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                'Pending: ${data['unresolved'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              Text(
                                'Resolved: ${data['resolved'] ?? 0}',
                                style: const TextStyle(
                                  fontSize: 14,
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          );
                        } catch (e) {
                          return const Text('N/A');
                        }
                      }
                      return const Text('N/A');
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
              InventoryTile(
                title: StringUtil.localize(context).label_open_tasks,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '0 Priced: ${profileProvider.profile.tasksCount['zeroCostItem'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      'POS Button: ${profileProvider.profile.tasksCount['updatedPosItem'] ?? 0}',
                      style: const TextStyle(
                        fontSize: 14,
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
              ),
              InventoryTile(
                title: StringUtil.localize(context).label_complete,
                child: FutureBuilder(
                  future: FirebaseFunctions.instance
                      .httpsCallable('users-getInvoicePeriodScore')
                      .call(
                    {
                      'userId': profileProvider.profile.id,
                    },
                  ),
                  builder: (context, snapshot) {
                    if (snapshot.connectionState == ConnectionState.done) {
                      if (snapshot.hasData) {
                        try {
                          final result = snapshot.data as HttpsCallableResult;
                          final data = result.data as num;
                          final value = (data * 100).round();
                          return Text(
                            '$value%',
                            style: const TextStyle(
                              fontSize: 18,
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          );
                        } catch (e) {
                          return const Text('N/A');
                        }
                      }
                      return const Text('N/A');
                    }
                    return const CircularProgressIndicator();
                  },
                ),
              ),
            ],
          ),
        ),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 8.0),
          child: SearchTextField(
            controller: _textController,
            onChanged: (value) {
              setState(() {
                _query = value;
                itemProvider.queryString = value;
              });
              _scrollController.jumpTo(0);
            },
            hintText: StringUtil.localize(context).hint_text_search_items,
            clearCallback: () {
              setState(() {
                _textController.clear();
                _query = _textController.text;
                itemProvider.queryString = '';
              });
            },
          ),
        ),
        const ItemFilters(filterSetting: FilterSetting.inventory),
        Align(
          alignment: Alignment.centerRight,
          child: Container(
            alignment: Alignment.centerRight,
            padding: const EdgeInsets.symmetric(vertical: 2, horizontal: 16),
            child: Text(StringUtil.localize(context).label_on_hand),
          ),
        ),
        (results.isEmpty)
            ? Center(
                child: Text(StringUtil.localize(context).label_no_items_found))
            : Expanded(
                child: NotificationListener<ScrollNotification>(
                  onNotification: (scrollNotification) {
                    return CountItemSearchButton.onNotification(
                      context,
                      scrollNotification,
                    );
                  },
                  child: ListView.separated(
                    key: const PageStorageKey<String>('itemsScrollController'),
                    controller: _scrollController,
                    separatorBuilder: (context, index) => const Padding(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      child: Divider(thickness: 2),
                    ),
                    itemCount: results.length + 1,
                    itemBuilder: (context, index) {
                      if (index == results.length) {
                        return const Padding(
                          padding: EdgeInsets.symmetric(horizontal: 8.0),
                          child: SizedBox(
                            height: 68,
                          ),
                        );
                      }
                      return Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8.0),
                        child: InventoryListTile(item: results[index]),
                      );
                    },
                  ),
                ),
              ),
      ],
    );
  }
}

class InventoryTile extends StatelessWidget {
  final String title;
  final Widget child;

  const InventoryTile({
    Key? key,
    required this.title,
    required this.child,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    const titleContainerHeight = 16.0;
    final isDesktop = Responsive.isDesktop(context);

    var mobileWidth = MediaQuery.of(context).size.width / 6 + 8;
    var desktopWidth =
        (Constants.largeScreenSize - Constants.navRailWidth * 2) / 6 + 8;
    var width = isDesktop ? desktopWidth : mobileWidth;
    var height = width;

    return Container(
      clipBehavior: Clip.hardEdge,
      margin: const EdgeInsets.all(4.0),
      width: width,
      height: height,
      decoration: BoxDecoration(
        color:
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8.0),
        border: Border.all(
          color: AppTheme.instance.themeData.colorScheme.primary,
          width: 2.0,
          style: BorderStyle.solid,
        ),
      ),
      child: Stack(
        alignment: Alignment.topCenter,
        children: [
          Positioned(
            top: titleContainerHeight,
            left: 0,
            child: Container(
              alignment: Alignment.center,
              width: width - 4,
              height: height - titleContainerHeight - 4,
              decoration: BoxDecoration(
                color: Theme.of(context)
                    .colorScheme
                    .secondaryContainer
                    .withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                    bottomLeft: Radius.circular(8.0),
                    bottomRight: Radius.circular(8.0)),
              ),
              child: Center(child: child),
            ),
          ),
          Container(
            alignment: Alignment.topCenter,
            width: 400,
            height: titleContainerHeight,
            decoration: BoxDecoration(
              color: AppTheme.instance.themeData.colorScheme.primary,
            ),
            child: Center(
              child: Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: AppTheme.instance.themeData.colorScheme.background,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
