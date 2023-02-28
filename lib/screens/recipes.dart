// Flutter Packages
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/widgets/shimmer/recipe_shimmer.dart';

// Widgets
import '../../../widgets/features/recipes/recipe_list.dart';

// Providers
import '../providers/data/items.dart';
import '../providers/data/recipes.dart';

class RecipesPage extends StatelessWidget {
  const RecipesPage({
    Key? key,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final recipeProvider = context.watch<RecipeProvider>();

    final recipes = recipeProvider.recipes;
    final items = itemProvider.getAllItems();

    if (itemProvider.isLoadingItems || recipeProvider.isLoading) {
      return const RecipeShimmer();
    }

    return RecipesList(
      recipes: recipes,
      items: items,
    );
  }
}
