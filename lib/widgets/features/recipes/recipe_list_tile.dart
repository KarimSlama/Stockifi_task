// Flutter Packages
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/providers/data/count_items.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/dishes_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/edit_recipe_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/recipe_ui_provider.dart';
import 'package:stocklio_flutter/screens/create_dish.dart';
import 'package:stocklio_flutter/screens/create_recipe_new.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/enums.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/text_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/page.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/common/search_item.dart';
import 'package:stocklio_flutter/widgets/features/recipes/recipe_body.dart';

// Models
import '../../../models/recipe.dart';

// Providers
import '../../../screens/in_progress_new.dart';
import '../../../utils/string_util.dart';

class RecipeListTile extends StatefulWidget {
  final Recipe recipe;
  final String query;
  final int index;
  final bool isExpandedBySearch;
  final RecipeType recipeType;

  const RecipeListTile({
    super.key,
    required this.recipe,
    this.query = '',
    this.index = 0,
    this.isExpandedBySearch = false,
  }) : recipeType = RecipeType.prebatch;

  const RecipeListTile.dishes({
    super.key,
    required this.recipe,
    this.query = '',
    this.index = 0,
    this.isExpandedBySearch = false,
  }) : recipeType = RecipeType.dish;

  @override
  State<RecipeListTile> createState() => _RecipeListTileState();
}

class _RecipeListTileState extends State<RecipeListTile> {
  @override
  Widget build(BuildContext context) {
    final isDesktop = Responsive.isDesktop(context);
    final isExpanded = widget.isExpandedBySearch ||
        context.watch<RecipeUIProvider>().isRecipeExpanded(widget.recipe.id!);
    final profileProvider = context.watch<ProfileProvider>();
    final numberFormat = profileProvider.profile.numberFormat;
    var recipeUIProvider = context.watch<RecipeUIProvider>();
    final currentCount =
        context.read<CountProvider>().findStartedOrPendingCount();

    final isInCurrentCount = currentCount != null &&
        context
            .watch<CountItemProvider>()
            .isItemOrRecipeInCount(currentCount.id!, widget.recipe.id!);
    final isInRecipe = context
        .read<RecipeProvider>()
        .isItemOrRecipeInAnyRecipe(widget.recipe.id!);
    final isInPos = context
        .read<PosItemProvider>()
        .isItemOrRecipeInAnyPosItem(widget.recipe.id!);

    final isRecipeDeletable = !(isInCurrentCount || isInRecipe || isInPos);
    final itemProvider = context.read<ItemProvider>();
    final recipeItemsList = (widget.recipe.itemsV2).entries.toList();

    final isItemCutawayEnabled = profileProvider.profile.isItemCutawayEnabled;
    var cost = widget.recipe.cost;

    if (isItemCutawayEnabled) {
      cost = 0;
      for (var index = 0; index < recipeItemsList.length; index++) {
        var item = itemProvider.findById(recipeItemsList[index].key);
        if (item == null) {
          var recipe = context
              .read<RecipeProvider>()
              .findById(recipeItemsList[index].key);
          if (recipe != null) {
            item ??= Item.fromRecipe(context, recipe);
          }
        }

        if (item == null) {
          continue;
        }
        final cutaway = (isItemCutawayEnabled && item.type == 'Mat')
            ? (item.cutaway) + 1
            : 1;
        cost += ParseUtil.toDouble(recipeItemsList[index].value) *
            item.cost *
            cutaway;
      }
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SearchItem(
          onTap: () {
            context
                .read<RecipeUIProvider>()
                .toggleRecipeExpanded(widget.recipe.id!, !isExpanded);
          },
          name: widget.recipe.name ?? '',
          size: widget.recipe.size.toString(),
          unit: widget.recipe.unit.toString(),
          variety: widget.recipe.variety.toString(),
          query: widget.query,
          cost: StringUtil.formatNumber(
            context.read<ProfileProvider>().profile.numberFormat,
            cost,
          ),
          subtitle: LayoutBuilder(builder: (context, constraints) {
            return GestureDetector(
              onTap: () {
                if (TextUtil.hasTextOverflow(
                  widget.recipe.name!,
                  style: Theme.of(context).textTheme.titleSmall!,
                  maxWidth: constraints.maxWidth,
                )) {
                  !recipeUIProvider.isPressed
                      ? StringUtil.showLongText(
                          context,
                          '${widget.recipe.size}${widget.recipe.unit ?? 'ml'}',
                          recipeUIProvider.setIsPressed,
                        )
                      : StringUtil.truncateLongText(
                          recipeUIProvider.setIsPressed);
                }
              },
              child: recipeUIProvider.isPressed
                  ? Text(
                      '${widget.recipe.size}${widget.recipe.unit ?? 'ml'}',
                    )
                  : Text(
                      '${widget.recipe.size}${widget.recipe.unit ?? 'ml'}',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
            );
          }),
          trailing: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                StringUtil.formatNumber(numberFormat, cost),
                style: TextStyle(
                  color: cost <= 0 ? Colors.red : null,
                  fontWeight: FontWeight.bold,
                ),
              ),
              widget.recipe.archived
                  ? IconButton(
                      onPressed: () async {
                        final isConfirmed = await confirm(
                          context,
                          Text(StringUtil.localize(context)
                              .message_confirm_remove_recipe_archives
                              .replaceAll(
                                "XXX",
                                '${widget.recipe.name}',
                              )),
                        );

                        if (isConfirmed) {
                          if (!mounted) return;
                          context
                              .read<RecipeProvider>()
                              .unarchiveRecipe(widget.recipe.id!);

                          showToast(
                              context,
                              StringUtil.localize(context)
                                  .message_success_remove_item_archives
                                  .replaceAll("XXX", '${widget.recipe.name}'));
                        }
                      },
                      icon: Icon(
                        Icons.archive,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    )
                  : IconButton(
                      icon: const Icon(Icons.edit),
                      onPressed: () {
                        if (widget.recipeType == RecipeType.prebatch) {
                          context.read<EditRecipeUIProvider>().recipe =
                              widget.recipe;
                        } else {
                          context.read<DishesUIProvider>().recipe =
                              widget.recipe;
                        }

                        if (widget.recipe.isPOSItem) {
                          return GoRouter.of(context).go(
                              '/home/lists/edit-pos-item/${widget.recipe.id}');
                        }

                        // TODO: Put this in a separate route similar to Edit Item and Edit POS Button
                        Navigator.of(context, rootNavigator: true).push(
                          InProgressRoute(
                            fullscreenDialog: true,
                            builder: (context) {
                              final editRecipeUIProvider =
                                  context.watch<EditRecipeUIProvider>();
                              final dishesUIProvider =
                                  context.watch<DishesUIProvider>();

                              return StocklioModal(
                                fullscreenDialog: true,
                                title: widget.recipeType == RecipeType.prebatch
                                    ? StringUtil.localize(context)
                                        .label_edit_prebatch
                                    : StringUtil.localize(context)
                                        .label_edit_menu_item,
                                onClose: () async {
                                  ///TODO: Need also to implement this object comparison for dishes
                                  var compareRecipe =
                                      editRecipeUIProvider.recipe ==
                                          widget.recipe;
                                  var compareDish =
                                      dishesUIProvider.recipe == widget.recipe;

                                  bool hasNoChanges = false;

                                  switch (widget.recipeType) {
                                    case RecipeType.prebatch:
                                      hasNoChanges = compareRecipe;
                                      break;
                                    case RecipeType.dish:
                                      hasNoChanges = compareDish;
                                      break;
                                    default:
                                  }

                                  if (hasNoChanges) {
                                    return Navigator.pop(context);
                                  } else {
                                    final isConfirmed = await confirm(
                                      context,
                                      Text(StringUtil.localize(context)
                                          .message_title_no_change_recipe),
                                      content: StringUtil.localize(context)
                                          .message_content_no_change_recipe,
                                    );

                                    if (isConfirmed && mounted) {
                                      if (widget.recipeType ==
                                          RecipeType.prebatch) {
                                        editRecipeUIProvider.resetRecipe();
                                      } else {
                                        dishesUIProvider.resetRecipe();
                                      }

                                      return Navigator.pop(context);
                                    }
                                  }
                                },
                                actions: [
                                  IconButton(
                                    onPressed: () async {
                                      final localizations =
                                          StringUtil.localize(context);
                                      if (isInCurrentCount) {
                                        showToast(
                                          context,
                                          '${localizations.message_recipe_in_current_count} ${localizations.message_recipe_cannot_archived}',
                                        );
                                      } else if (isInRecipe) {
                                        showToast(
                                          context,
                                          '${localizations.message_recipe_used_in_another_recipe}  ${localizations.message_recipe_cannot_archived}',
                                        );
                                      } else if (isInPos) {
                                        showToast(
                                          context,
                                          '${localizations.message_recipe_used_in_pos_item} ${localizations.message_recipe_cannot_archived}',
                                        );
                                      } else {
                                        await confirm(
                                          context,
                                          Text(
                                            localizations
                                                .message_confirm_archive_recipe
                                                .replaceAll("XXX",
                                                    '${widget.recipe.name}?'),
                                          ),
                                        ).then((value) async {
                                          if (value) {
                                            Navigator.pop(context);
                                            await context
                                                .read<RecipeProvider>()
                                                .archiveRecipe(
                                                    widget.recipe.id!);
                                          }
                                        });
                                      }
                                    },
                                    icon: const Icon(Icons.archive),
                                  ),
                                  IconButton(
                                    onPressed: () async {
                                      final localizations =
                                          StringUtil.localize(context);
                                      if (isInCurrentCount) {
                                        showToast(
                                          context,
                                          '${localizations.message_recipe_in_current_count} ${localizations.message_recipe_cannot_deleted}',
                                        );
                                      } else if (isInRecipe) {
                                        showToast(
                                          context,
                                          '${localizations.message_recipe_used_in_another_recipe}  ${localizations.message_recipe_cannot_deleted}',
                                        );
                                      } else if (isInPos) {
                                        showToast(
                                          context,
                                          '${localizations.message_recipe_used_in_pos_item} ${localizations.message_recipe_cannot_deleted}',
                                        );
                                      } else {
                                        await confirm(
                                          context,
                                          Text(
                                            '${localizations.message_confirm_delete_item.replaceAll("item", 'recipe')} ${widget.recipe.name}',
                                          ),
                                        ).then((value) async {
                                          if (value) {
                                            Navigator.pop(context);
                                            await context
                                                .read<RecipeProvider>()
                                                .softDeleteRecipe(
                                                    widget.recipe.id!);
                                          }
                                        });
                                      }
                                    },
                                    icon: Icon(
                                      Icons.delete,
                                      color: isRecipeDeletable
                                          ? Colors.red
                                          : AppTheme
                                              .instance.themeData.disabledColor,
                                    ),
                                  ),
                                ],
                                child: Center(
                                  child: Container(
                                    alignment: Alignment.topCenter,
                                    width: isDesktop
                                        ? Constants.largeScreenSize -
                                            Constants.navRailWidth * 2
                                        : null,
                                    child: widget.recipeType ==
                                            RecipeType.prebatch
                                        ? CreateRecipePage(
                                            recipe: widget.recipe)
                                        : CreateDishPage(recipe: widget.recipe),
                                  ),
                                ),
                              );
                            },
                          ),
                        );
                      },
                      color: Theme.of(context).colorScheme.primary,
                    ),
              IconButton(
                icon: Icon(isExpanded ? Icons.expand_less : Icons.expand_more),
                color: Theme.of(context).colorScheme.primary,
                onPressed: (widget.recipe.itemsV2).isNotEmpty
                    ? () {
                        context.read<RecipeUIProvider>().toggleRecipeExpanded(
                            widget.recipe.id!, !isExpanded);
                      }
                    : null,
              ),
            ],
          ),
        ),
        Visibility(
          visible: isExpanded && ((widget.recipe.itemsV2).isNotEmpty),
          child: RecipeBody(
            recipe: widget.recipe,
            ingredientQuery: widget.query,
          ),
        ),
      ],
    );
  }
}
