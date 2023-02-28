import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/providers/ui/recipe_list_ui_provider.dart';
import 'package:stocklio_flutter/screens/dishes.dart';
import 'package:stocklio_flutter/screens/recipes.dart';
import 'package:stocklio_flutter/utils/app_theme_util.dart';
import 'package:go_router/go_router.dart';
import 'package:stocklio_flutter/utils/string_util.dart';

import '../utils/router/go_router.dart';

class RecipesListsPage extends StatefulWidget {
  const RecipesListsPage({
    Key? key,
  }) : super(key: key);

  @override
  State<RecipesListsPage> createState() => _RecipesListsPageState();
}

class _RecipesListsPageState extends State<RecipesListsPage> {
  @override
  Widget build(BuildContext context) {
    final selectedRecipe = context
        .select<RecipeListUIProvider, int>((value) => value.recipeListIndex);

    return Scaffold(
      appBar: PreferredSize(
        preferredSize: const Size.fromHeight(120),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () => _handleRadioTap(0),
              child: Row(
                children: [
                  Radio<int>(
                    value: 0,
                    groupValue: selectedRecipe,
                    activeColor:
                        AppTheme.instance.themeData.colorScheme.primary,
                    onChanged: (value) {
                      _handleRadioTap(value!);
                    },
                  ),
                  _RadioLabel(
                      StringUtil.localize(context).radio_label_prebatches,
                      '🍲'),
                ],
              ),
            ),
            GestureDetector(
              onTap: () => _handleRadioTap(1),
              child: Row(
                children: [
                  Radio<int>(
                      value: 1,
                      groupValue: selectedRecipe,
                      activeColor:
                          AppTheme.instance.themeData.colorScheme.primary,
                      onChanged: (value) {
                        _handleRadioTap(value!);
                      }),
                  _RadioLabel(
                      StringUtil.localize(context).radio_label_dishes, '🍽️'),
                ],
              ),
            ),
          ],
        ),
      ),
      body: selectedRecipe == 0 ? const RecipesPage() : const DishesPage(),
    );
  }

  void _handleRadioTap(int radioIndex) {
    final isAdmin = context.read<AuthProvider>().isAdmin;
    final profile = context.read<ProfileProvider>().profile;

    final recipeType = RouterUtil.recipeTypeRoutes[radioIndex];

    if (isAdmin) {
      context.go(
          '/admin/lists/recipes?selectedProfileId=${profile.id}&recipeType=$recipeType');
    } else {
      context.go('/lists/recipes?recipeType=$recipeType');
    }
  }
}

class _RadioLabel extends StatelessWidget {
  final String text;
  final dynamic emoji;

  const _RadioLabel(
    this.text,
    this.emoji, {
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Text(
      '$text $emoji',
      style: const TextStyle(
        fontWeight: FontWeight.bold,
        overflow: TextOverflow.ellipsis,
      ),
    );
  }
}
