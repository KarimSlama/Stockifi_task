import 'package:stocklio_flutter/models/base_item.dart';

class CountItemHelper {
  String countItemId;
  String countItemAreaId;
  double countItemQuantity;
  double countItemExtra;
  bool? countItemIsPerKilo;
  bool? countItemIsCorrectCount;
  String countItemCalc;
  BaseItem? baseItem;
  int countItemUpdated;
  num countItemCost;

  CountItemHelper(
    this.countItemId,
    this.countItemAreaId,
    this.countItemQuantity,
    this.countItemExtra,
    this.countItemIsPerKilo,
    this.countItemIsCorrectCount,
    this.countItemCalc,
    this.baseItem,
    this.countItemUpdated,
    this.countItemCost,
  );

  @override
  bool operator ==(other) =>
      other is CountItemHelper && countItemId == other.countItemId;

  @override
  int get hashCode => countItemId.hashCode;
}
