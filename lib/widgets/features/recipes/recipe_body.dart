import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/models/recipe.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/count_item_search_fab_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/recipe_ui_provider.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:stocklio_flutter/utils/constants.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';
import 'package:stocklio_flutter/utils/text_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:stocklio_flutter/widgets/common/padded_text.dart';
import 'package:stocklio_flutter/widgets/common/responsive.dart';
import 'package:stocklio_flutter/widgets/features/recipes/recipe_header.dart';

import '../../../models/item.dart';
import '../../../utils/string_util.dart';

class RecipeBody extends StatefulWidget {
  final Recipe recipe;
  final String ingredientQuery;

  const RecipeBody({
    Key? key,
    required this.recipe,
    this.ingredientQuery = '',
  }) : super(key: key);

  @override
  State<RecipeBody> createState() => _RecipeBodyState();
}

class _RecipeBodyState extends State<RecipeBody> {
  ScrollController noteScrollController = ScrollController();
  final noteTextController = TextEditingController();
  final noteTextFocus = FocusNode();

  bool hasScrollbar = true;
  bool isExpanded = false;
  bool isTextFieldVisible = false;
  bool isTextFieldEmpty = true;
  bool isScrollerAttached = false;
  bool isSavingNote = false;
  @override
  void initState() {
    super.initState();

    if (widget.recipe.note != null) {
      noteTextController.text = widget.recipe.note!;
      if (noteTextController.text.isNotEmpty) {
        isTextFieldEmpty = false;
      }
    }
    noteTextFocus.addListener(_onFocusChange);
    noteTextController.addListener(_onTextFieldChange);
  }

  @override
  void dispose() {
    noteScrollController.dispose();
    noteTextController.removeListener(_onTextFieldChange);
    noteTextController.dispose();
    noteTextFocus.removeListener(_onFocusChange);
    noteTextFocus.dispose();
    super.dispose();
  }

  void _onFocusChange() {
    if (noteTextFocus.hasFocus) {
      context.read<CountItemSearchFabUIProvider>().setIsSearchFabEnabled(false);
      setState(() {
        isExpanded = true;
      });
    } else {
      context.read<CountItemSearchFabUIProvider>().setIsSearchFabEnabled(true);
      setState(() {
        int count = countLine();
        isExpanded = count > 1;
      });
    }
  }

  void _onTextFieldChange() {
    setState(() {
      isTextFieldEmpty = noteTextController.text.isEmpty;
    });
  }

  int countLine() => (noteTextController.text.length /
          (MediaQuery.of(context).size.width * 0.06))
      .round();

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.read<ItemProvider>();
    final recipeItemsList = (widget.recipe.itemsV2).entries.toList();
    final profileProvider = context.watch<ProfileProvider>();
    final numberFormat = profileProvider.profile.numberFormat;
    final isRecipeNoteEnabled = profileProvider.profile.isRecipeNoteEnabled;
    final isMoreThanOneLine = countLine() > 1;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 8.0),
      child: Column(
        children: [
          if (isRecipeNoteEnabled)
            Stack(
              children: [
                NotificationListener<ScrollMetricsNotification>(
                  onNotification: (scrollNotification) {
                    setState(() {
                      hasScrollbar =
                          (scrollNotification.metrics.maxScrollExtent > 0);
                    });
                    return hasScrollbar;
                  },
                  child: SingleChildScrollView(
                    controller: noteScrollController,
                    scrollDirection: Axis.vertical,
                    child: Column(
                      children: [
                        Row(
                          children: [
                            InkWell(
                              onTap: (widget.recipe.note != null &&
                                      widget.recipe.note!.isNotEmpty)
                                  ? null
                                  : () {
                                      setState(() {
                                        isTextFieldVisible =
                                            !isTextFieldVisible;
                                      });
                                    },
                              child: Ink(
                                  child: const Icon(
                                Icons.note_alt_outlined,
                              )),
                            ),
                            const SizedBox(
                              width: Constants.defaultPadding,
                            ),
                            const Text("Notes"),
                          ],
                        ),
                        Container(
                          height: isExpanded ||
                                  noteTextFocus.hasFocus ||
                                  !isMoreThanOneLine
                              ? null
                              : 40, //null to take the whole height of child
                          decoration: BoxDecoration(
                            color: AppTheme.instance.rowColor,
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: Theme.of(context).colorScheme.primary,
                            ),
                          ),
                          padding: const EdgeInsets.symmetric(
                                  vertical: 8, horizontal: 24)
                              .copyWith(left: 12),
                          child: TextField(
                            controller: noteTextController,
                            textInputAction: TextInputAction.done,
                            focusNode: noteTextFocus,
                            decoration: InputDecoration.collapsed(
                              fillColor: AppTheme.instance.rowColor,
                              filled: true,
                              hintText:
                                  StringUtil.localize(context).label_add_note,
                            ),
                            maxLines: null,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                if ((widget.recipe.note != null &&
                        widget.recipe.note!.isNotEmpty) &&
                    (hasScrollbar || !isExpanded || !noteTextFocus.hasFocus) &&
                    isMoreThanOneLine)
                  Positioned(
                    bottom: 4,
                    right: 8,
                    child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                          noteTextFocus.unfocus();
                        },
                        child: Icon(isExpanded
                            ? Icons.fullscreen_exit_rounded
                            : Icons.fullscreen_rounded)),
                  ),
                if (noteTextFocus.hasFocus && !isTextFieldEmpty)
                  Positioned(
                    bottom: 4,
                    right: 8,
                    child: GestureDetector(
                        onTap: () {
                          setState(() {
                            isExpanded = !isExpanded;
                          });
                        },
                        child: InkWell(
                          onTap: isSavingNote
                              ? null
                              : () async {
                                  if (!isTextFieldEmpty) {
                                    setState(() {
                                      isSavingNote = true;
                                    });
                                    final recipe = widget.recipe.copyWith(
                                        note: noteTextController.text);

                                    final result = await context
                                        .read<RecipeProvider>()
                                        .updateRecipe(recipe);

                                    if (result == 'Recipe updated' && mounted) {
                                      showToast(
                                          context, 'Recipe note updated.');
                                      setState(() {
                                        isSavingNote = false;
                                      });
                                    }
                                  }
                                },
                          child: isSavingNote
                              ? Container(
                                  alignment: Alignment.center,
                                  padding: const EdgeInsets.all(4.0),
                                  width: 24,
                                  height: 24,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2.6,
                                    color: AppTheme
                                        .instance.themeData.colorScheme.primary,
                                  ),
                                )
                              : Ink(
                                  child: Icon(
                                    Icons.save,
                                    color: AppTheme
                                        .instance.themeData.colorScheme.primary,
                                  ),
                                ),
                        )),
                  ),
              ],
            ),
          const ItemsHeader(),
          ListView.builder(
            physics: const NeverScrollableScrollPhysics(),
            shrinkWrap: true,
            itemCount: recipeItemsList.length,
            itemBuilder: (context, index) {
              var item = itemProvider.findById(recipeItemsList[index].key);
              if (item == null) {
                var recipe = context
                    .read<RecipeProvider>()
                    .findById(recipeItemsList[index].key);
                if (recipe != null) {
                  item ??= Item.fromRecipe(context, recipe);
                }
              }

              num partSize;
              double cost;

              if (item == null) {
                return const SizedBox();
              }
              final isItemCutawayEnabled =
                  profileProvider.profile.isItemCutawayEnabled;
              final cutaway = (isItemCutawayEnabled && item.type == 'Mat')
                  ? (item.cutaway) + 1
                  : 1;

              partSize = ParseUtil.toNum(recipeItemsList[index].value) *
                  (item.size ?? 0);
              cost = ParseUtil.toDouble(recipeItemsList[index].value) *
                  item.cost *
                  cutaway;

              var recipeUIProvider = context.watch<RecipeUIProvider>();

              return Container(
                color: index.isEven ? AppTheme.instance.rowColor : null,
                child: Row(
                  children: [
                    Expanded(
                      flex: 6,
                      child: LayoutBuilder(
                        builder: (context, constraints) {
                          return GestureDetector(
                            onTap: () {
                              if (TextUtil.hasTextOverflow(
                                item!.name!,
                                maxWidth: constraints.maxWidth,
                                totalHorizontalPadding: 16,
                              )) {
                                !recipeUIProvider.isPressed
                                    ? StringUtil.showLongText(
                                        context,
                                        item.name!,
                                        recipeUIProvider.setIsPressed,
                                      )
                                    : StringUtil.truncateLongText(
                                        recipeUIProvider.setIsPressed,
                                      );
                              }
                            },
                            child: recipeUIProvider.isPressed
                                ? Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: RichText(
                                      text: TextSpan(
                                        children: [
                                          ...TextUtil.highlightSearchText(
                                              context,
                                              item!.name!,
                                              widget.ingredientQuery),
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
                                              item!.name!,
                                              widget.ingredientQuery),
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
                        '${StringUtil.formatNumber(numberFormat, partSize)}${item.unit}',
                        textAlign: TextAlign.right,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    if (isItemCutawayEnabled)
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
                        StringUtil.formatNumber(numberFormat, cost),
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
