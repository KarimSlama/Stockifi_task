// Flutter Packages
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/pos_items.dart';
import 'package:stocklio_flutter/providers/data/users.dart';
import 'package:stocklio_flutter/widgets/shimmer/recipe_shimmer.dart';

// Widgets
import '../../../widgets/features/recipes/recipe_list.dart';

// Providers
import '../providers/data/items.dart';
import '../providers/data/recipes.dart';

class DishesPage extends StatelessWidget {
  const DishesPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final itemProvider = context.watch<ItemProvider>();
    final recipeProvider = context.watch<RecipeProvider>();
    final profileProvider = context.watch<ProfileProvider>();

    bool isLoading = itemProvider.isLoadingItems || recipeProvider.isLoading;

    if (profileProvider.profile.isPosItemsAsMenuItemsEnabled) {
      final posItemProvider = context.watch<PosItemProvider>()
        ..posItems
        ..getArchivedPosItems();
      isLoading = isLoading ||
          posItemProvider.isLoading ||
          posItemProvider.isLoadingArchivedPosItems;
    }

    final dishes = recipeProvider.menuItems;
    final items = itemProvider.getAllItems();

    if (isLoading) {
      return const RecipeShimmer();
    }

    return RecipesList.dishes(recipes: dishes, items: items);
  }
}
