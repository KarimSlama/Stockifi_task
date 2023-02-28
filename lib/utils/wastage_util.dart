import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/models/wastage_item.dart';

class WastageUtil {
  static num getWastageTotal(
    WastageItem wastageItem,
    Item item,
  ) {
    num totalCost = 0;

    for (var element in (wastageItem.items ?? {}).entries) {
      totalCost += element.value * item.cost;
    }

    return totalCost;
  }
}
