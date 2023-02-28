import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/app_config.dart';
import 'package:stocklio_flutter/providers/data/count_areas.dart';
import 'package:stocklio_flutter/providers/data/count_items.dart';
import 'package:stocklio_flutter/providers/data/counts.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/data/recipes.dart';
import 'package:stocklio_flutter/providers/data/tasks.dart';
import 'package:stocklio_flutter/providers/data/users.dart';

class StreamSubscriptionHelper {
  void cancelGroupStreamSubscription(BuildContext context) {
    final appconfigProvider = context.read<AppConfigProvider>();
    appconfigProvider.cancelStreamSubscriptions();

    final countAreaProvider = context.read<CountAreaProvider>();
    countAreaProvider.cancelStreamSubscriptions();

    final countItemProvider = context.read<CountItemProvider>();
    countItemProvider.cancelStreamSubscriptions();

    final itemProvider = context.read<ItemProvider>();
    itemProvider.cancelStreamSubscriptions();

    final recipeProvider = context.read<RecipeProvider>();
    recipeProvider.cancelStreamSubscriptions();

    final taskProvider = context.read<TaskProvider>();
    taskProvider.cancelStreamSubscriptions();

    final countProvider = context.read<CountProvider>();
    countProvider.cancelStreamSubscriptions();

    final profileProvider = context.read<ProfileProvider>();
    profileProvider.cancelStreamSubscriptions();
  }
}
