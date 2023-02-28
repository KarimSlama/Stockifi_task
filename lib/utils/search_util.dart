import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:stocklio_flutter/providers/data/items.dart';
import 'package:stocklio_flutter/providers/ui/pos_item_ui.dart';
import 'package:stocklio_flutter/providers/ui/recipe_ui_provider.dart';
import 'package:stocklio_flutter/providers/ui/wastage_ui_provider.dart';

class SearchUtil {
  static void clearAllListSearch(BuildContext context) {
    context.read<RecipeUIProvider>().queryString = '';
    context.read<POSItemUIProvider>().posItemsQueryString = '';
    context.read<WastageUIProvider>().queryString = '';
    context.read<ItemProvider>().queryString = '';
  }
}
