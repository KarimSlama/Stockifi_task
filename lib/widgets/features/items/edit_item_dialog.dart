import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:stocklio_flutter/models/recipe.dart';
import 'package:stocklio_flutter/models/task.dart';
import 'package:stocklio_flutter/providers/data/count_items.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/tasks.dart';
import 'package:stocklio_flutter/screens/create_item.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/widgets/common/page.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import '../../../providers/data/items.dart';
import '../../../providers/data/notifications.dart';
import '../../../widgets/common/confirm.dart';
import 'package:provider/provider.dart';

class EditItemDialog extends StatefulWidget {
  const EditItemDialog({
    Key? key,
    required this.itemId,
    this.taskId,
  }) : super(key: key);

  final String? itemId;
  final String? taskId;

  @override
  State<EditItemDialog> createState() => _EditItemDialogState();
}

class _EditItemDialogState extends State<EditItemDialog> {
  @override
  void initState() {
    super.initState();
    final countProvider = context.read<CountProvider>()..counts;
    final count = countProvider.findPendingCount();

    if (count != null) {
      countProvider.updateCountStateToStarted(count);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final itemProvider = context.watch<ItemProvider>()..getItems();
    final posItemProvider = context.watch<PosItemProvider>()..posItems;
    final recipeProvider = context.watch<RecipeProvider>()..menuItems;
    final notificationProvider = context.watch<NotificationProvider>()
      ..notifications;

    if (itemProvider.isLoadingItems ||
        notificationProvider.isLoading ||
        recipeProvider.isLoading ||
        posItemProvider.isLoading) {
      return const Material(
        child: Center(
          child: CircularProgressIndicator(),
        ),
      );
    }

    final item = itemProvider.findById(widget.itemId!);

    if (item == null) return const SizedBox();

    final currentCount =
        context.read<CountProvider>().findStartedOrPendingCount();

    final isInRecipe =
        context.read<RecipeProvider>().isItemOrRecipeInAnyRecipe(item.id!);
    final isInPos =
        context.read<PosItemProvider>().isItemOrRecipeInAnyPosItem(item.id!);
    final isInCurrentCount = currentCount != null &&
        context
            .watch<CountItemProvider>()
            .isItemOrRecipeInCount(currentCount.id!, item.id!);

    final isDeletable = !(isInRecipe || isInPos || isInCurrentCount);

    return StocklioModal(
      title: 'Edit item',
      onClose: () {
        final canPop = context.canPop();
        if (canPop) {
          context.pop();
        } else {
          context.goNamed('lists');
        }
      },
      actions: [
        IconButton(
          onPressed: isDeletable
              ? () async {
                  final isConfirmed = await confirm(
                      context,
                      Text(
                          '${StringUtil.localize(context).message_confirm_edit_item} ${item.name}?'));

                  if (isConfirmed) {
                    itemProvider.archiveItem(item.id!);
                    if (mounted) {
                      showToast(context,
                          '${item.name} ${StringUtil.localize(context).message_success_edit_item}');
                    }
                    if (mounted) Navigator.pop(context);
                  }
                }
              : null,
          icon: const Icon(Icons.archive),
        ),
        GestureDetector(
          onTap: !isDeletable
              ? () {
                  final notificationProvider =
                      context.read<NotificationProvider>();

                  String? message;
                  String? title;

                  if (isInRecipe) {
                    List<Recipe> prebatches = [];
                    List<Recipe> dishes = [];

                    for (var recipeId in recipeProvider.itemsInRecipes) {
                      final dish = recipeProvider.findDishById(recipeId);

                      if (dish == null) {
                        final prebatch =
                            recipeProvider.findPrebatchById(recipeId);
                        if (prebatch != null) prebatches.add(prebatch);
                      } else {
                        dishes.add(dish);
                      }
                    }

                    if (dishes.isNotEmpty) {
                      title = 'Item ${item.name} cannot be deleted';
                      message =
                          'Item is used in ${dishes.length} ${dishes.length > 1 ? 'Dishes' : 'Dish'}. Item cannot be deleted.';

                      showToast(context, message);
                      notificationProvider.createNotification(
                        title: title,
                        body: message,
                        data: {'item': item.toJson()},
                        path:
                            '/lists/recipes?search_query=${item.name}&recipeType=dish',
                      );
                    }

                    if (prebatches.isNotEmpty) {
                      title = 'Item ${item.name} cannot be deleted';
                      message =
                          'Item is used in ${prebatches.length} ${prebatches.length > 1 ? 'Prebatches' : 'Prebatch'}. Item cannot be deleted.';

                      showToast(context, message);
                      notificationProvider.createNotification(
                        title: title,
                        body: message,
                        data: {'item': item.toJson()},
                        path:
                            '/lists/recipes?search_query=${item.name}&recipeType=prebatch',
                      );
                    }
                  }

                  if (isInPos) {
                    final length = posItemProvider.itemsInPOS.length;

                    title = 'Item ${item.name} cannot be deleted';
                    message =
                        'Item is used in $length ${length > 1 ? 'POS Buttons' : 'POS Button'}. Item cannot be deleted.';

                    showToast(context, message);
                    notificationProvider.createNotification(
                      title: title,
                      body: message,
                      data: {'item': item.toJson()},
                      path: '/lists/posbuttons?search_query=${item.name}',
                    );
                  }

                  if (isInCurrentCount) {
                    message = StringUtil.localize(context)
                        .message_invalid_delete_item;
                    showToast(context, message);
                  }
                }
              : null,
          child: IconButton(
            onPressed: isDeletable
                ? () async {
                    final isConfirmed = await confirm(
                        context,
                        Text(
                            '${StringUtil.localize(context).message_confirm_delete_item} ${item.name}?'));
                    if (isConfirmed) {
                      if (mounted) {
                        await context
                            .read<ItemProvider>()
                            .updateItemDeleted(item, true);
                      }

                      if (mounted) {
                        context.read<TaskProvider>().softDeleteTask(
                          type: TaskType.zeroCostItem,
                          path: '/edit-item/${item.id}',
                          data: {'itemId': item.id},
                        );
                      }

                      if (mounted) {
                        showToast(
                            context,
                            StringUtil.localize(context)
                                .message_success_delete_item);
                      }
                      if (mounted) Navigator.pop(context);
                    }
                  }
                : null,
            icon: Icon(
              Icons.delete,
              color: isDeletable ? Colors.red : null,
            ),
          ),
        ),
      ],
      child: Center(
        child: Container(
          alignment: Alignment.topCenter,
          width: isDesktop
              ? Constants.largeScreenSize - Constants.navRailWidth * 2
              : null,
          child: CreateItemPage(
            item: item,
            task: (widget.taskId == null)
                ? null
                : context.read<TaskProvider>().findById(widget.taskId!),
          ),
        ),
      ),
    );
  }
}
