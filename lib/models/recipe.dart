// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

import 'base_item.dart';

// Generated Files
part 'recipe.freezed.dart';
part 'recipe.g.dart';

@freezed
class Recipe with _$Recipe {
  @Implements<BaseItem>()
  factory Recipe({
    String? id,
    String? name,
    @Default('Recipe') String type,
    @Default('Recipe') String variety,
    @JsonKey(fromJson: ParseUtil.toInt) int? size,
    String? unit,
    @Default([]) List<String> sortedItemIds,
    @Default({}) Map<String, dynamic> itemsV2,
    @Default(false) bool perUnit,
    String? itemId,
    @JsonKey(fromJson: ParseUtil.toNum) @Default(0) num cost,
    String? silhouetteName,
    @Default(false) bool isDish,
    @Default(false) bool isPOSItem,
    @Default(false) bool deleted,
    @Default(false) bool archived,
    String? note,
    @Default([]) List<String> tags,
  }) = _Recipe;

  factory Recipe.fromJson(Map<String, dynamic> json) => _$RecipeFromJson(json);

  factory Recipe.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    data['type'] = 'Recipe';
    data['variety'] = (data['isDish'] ?? false) ? 'Menu Item' : 'Prebatch';
    data['unit'] = data['unit'] ?? 'ml';
    return Recipe.fromJson(data).copyWith(id: snapshot.id);
  }

  factory Recipe.fromPOSItem(PosItem posItem) {
    return Recipe(
      id: posItem.id,
      itemsV2: posItem.items,
      name: posItem.posData['name'] ?? '',
      cost: posItem.cost,
      isDish: true,
      type: 'Recipe',
      variety: 'Menu Item',
      archived: posItem.archived,
      isPOSItem: true,
      size: 1,
      unit: 'pcs',
    );
  }
}
