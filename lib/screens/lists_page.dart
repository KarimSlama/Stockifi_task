import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/screens/items.dart';
import 'package:stocklio_flutter/screens/recipes_lists_page.dart';
import 'package:stocklio_flutter/utils/router/go_router.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/features/pos_items/pos_items_list.dart';
import 'package:stocklio_flutter/widgets/features/wastage/wastage_view.dart';

import '../providers/data/auth.dart';

class ListsPage extends StatefulWidget {
  final int listsTabIndex;
  final int recipeTypeIndex;

  // ignore: prefer_const_constructors_in_immutables
  ListsPage({
    Key? key,
    this.listsTabIndex = 0,
    this.recipeTypeIndex = 0,
  }) : super(key: key);

  @override
  State<ListsPage> createState() => _ListsPageState();
}

class _ListsPageState extends State<ListsPage> with TickerProviderStateMixin {
  late final TabController _controller;

  @override
  void initState() {
    super.initState();

    final profile = context.read<ProfileProvider>().profile;

    _controller = TabController(
      length: profile.isPosItemsAsMenuItemsEnabled ? 3 : 4,
      vsync: this,
      initialIndex: widget.listsTabIndex,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  void didUpdateWidget(ListsPage oldWidget) {
    super.didUpdateWidget(oldWidget);
    _controller.index = widget.listsTabIndex;
  }

  @override
  Widget build(BuildContext context) {
    final localizations = StringUtil.localize(context);
    final profile = context.read<ProfileProvider>().profile;

    return Scaffold(
      appBar: TabBar(
        controller: _controller,
        padding: const EdgeInsets.only(bottom: 8),
        indicatorColor: Theme.of(context).colorScheme.primary,
        onTap: (value) {
          final isAdmin = context.read<AuthProvider>().isAdmin;

          final listsTab = RouterUtil.listsTabRoutes[value];
          if (isAdmin) {
            if (listsTab == 'recipes') {
              context.go(
                  '/admin/lists/$listsTab?selectedProfileId=${profile.id}&recipeType=prebatch');
            } else {
              context
                  .go('/admin/lists/$listsTab?selectedProfileId=${profile.id}');
            }
          } else {
            if (listsTab == 'recipes') {
              context.go('/lists/$listsTab?recipeType=prebatch');
            } else {
              context.go('/lists/$listsTab');
            }
          }
        },
        tabs: profile.isPosItemsAsMenuItemsEnabled
            ? [
                Tab(child: _TabLabel(localizations.label_items)),
                Tab(child: _TabLabel(localizations.label_recipes)),
                Tab(child: _AccessTabLabel(localizations.label_wastage)),
              ]
            : [
                Tab(child: _TabLabel(localizations.label_items)),
                Tab(child: _TabLabel(localizations.label_recipes)),
                Tab(child: _AccessTabLabel(localizations.label_pos_buttons)),
                Tab(child: _AccessTabLabel(localizations.label_wastage)),
              ],
      ),
      body: TabBarView(
        controller: _controller,
        children: profile.isPosItemsAsMenuItemsEnabled
            ? [
                const ItemsPage(),
                const RecipesListsPage(),
                const WastageView(),
              ]
            : [
                const ItemsPage(),
                const RecipesListsPage(),
                const POSItemsList(),
                const WastageView(),
              ],
      ),
    );
  }
}

class _TabLabel extends StatelessWidget {
  final String text;

  const _TabLabel(this.text, {Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      text,
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}

class _AccessTabLabel extends StatefulWidget {
  final String text;
  const _AccessTabLabel(this.text, {Key? key}) : super(key: key);

  @override
  State<_AccessTabLabel> createState() => _AccessTabLabelState();
}

class _AccessTabLabelState extends State<_AccessTabLabel> {
  @override
  Widget build(BuildContext context) {
    final profileProvider = context.watch<ProfileProvider>();
    final accessLevel = profileProvider.profile.accessLevel;
    return Stack(
      clipBehavior: Clip.none,
      alignment: Alignment.center,
      children: [
        Text(
          widget.text,
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        if (widget.text == StringUtil.localize(context).label_wastage &&
            !profileProvider.profile.isWastageEnabled)
          const Positioned(
            left: -20,
            child: Icon(
              Icons.lock_rounded,
              size: 14,
              color: Colors.amberAccent,
            ),
          )
        else if (widget.text != StringUtil.localize(context).label_wastage &&
            accessLevel < 3)
          const Positioned(
            left: -20,
            child: Icon(
              Icons.lock_rounded,
              size: 14,
              color: Colors.amberAccent,
            ),
          ),
      ],
    );
  }
}
