import 'package:flutter/material.dart';
import 'package:stocklio_flutter/screens/create_dish.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'create_item.dart';
import '../screens/create_recipe_new.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import '../widgets/common/page.dart';

class CreateDialog extends StatefulWidget {
  final int? initialIndex;
  final String newItemName;

  const CreateDialog({Key? key, this.initialIndex, this.newItemName = ''})
      : super(key: key);

  @override
  State<CreateDialog> createState() => _CreateDialogState();
}

class _CreateDialogState extends State<CreateDialog>
    with SingleTickerProviderStateMixin {
  final _itemsKey = GlobalKey<CreateItemPageState>();
  final _recipesKey = GlobalKey<CreateRecipePageState>();
  final _dishesKey = GlobalKey<CreateRecipePageState>();

  late final _tabController = TabController(
    length: 3,
    vsync: this,
    initialIndex: widget.initialIndex ?? 0,
  );

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    return StocklioModal(
      title: StringUtil.localize(context).label_add_new,
      child: Center(
        child: Container(
          alignment: Alignment.topCenter,
          width: isDesktop
              ? Constants.largeScreenSize - Constants.navRailWidth * 2
              : null,
          child: Column(
            children: [
              Container(
                color: Theme.of(context).colorScheme.background,
                child: TabBar(
                  indicatorColor: Theme.of(context).colorScheme.primary,
                  controller: _tabController,
                  tabs: [
                    PaddedText(
                      StringUtil.localize(context).label_item,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    PaddedText(
                      StringUtil.localize(context).label_prebatch,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    PaddedText(
                      StringUtil.localize(context).label_menu_item,
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
              Flexible(
                fit: FlexFit.loose,
                child: TabBarView(
                  controller: _tabController,
                  children: [
                    CreateItemPage(
                      key: _itemsKey,
                      newItemName: widget.newItemName,
                    ),
                    CreateRecipePage(key: _recipesKey),
                    CreateDishPage(key: _dishesKey),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
