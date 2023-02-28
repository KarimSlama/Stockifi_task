// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/models/recipe.dart';
import 'package:stocklio_flutter/utils/recipe_util.dart';

// Utils
import '../utils/parse_util.dart';
import 'base_item.dart';

// Generated Files
part 'item.freezed.dart';
part 'item.g.dart';

@freezed
class Item with _$Item {
  @Implements<BaseItem>()
  factory Item({
    String? id,
    String? name,
    String? type,
    String? variety,
    String? unit,
    String? itemId,
    @JsonKey(fromJson: ParseUtil.toInt) int? size,
    @JsonKey(fromJson: ParseUtil.toNum) @Default(0) num cost,
    @JsonKey(fromJson: ParseUtil.toNum) @Default(0) num cutaway,
    @JsonKey(fromJson: ParseUtil.toNum) @Default(0) num stock,
    num? avgCost,
    String? globalId,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
    @Default(false) bool deleted,
    @Default(false) bool starred,
    @Default(false) bool archived,
    Map<String, dynamic>? itemsV2, // Will always be null
    String? silhouetteName,
    @Default([]) List<String> tags,
  }) = _Item;

  factory Item.fromJson(Map<String, dynamic> json) => _$ItemFromJson(json);

  factory Item.fromSnapshot(DocumentSnapshot snapshot) {
    final data = snapshot.data() as Map<String, dynamic>;
    final globalDataField = data['globalData'];
    if (globalDataField != null) {
      data['size'] = globalDataField['size'] ?? data['size'];
      data['unit'] = globalDataField['unit'] ?? data['unit'];
      data['type'] = globalDataField['type'] ?? data['type'];
      data['variety'] = globalDataField['variety'] ?? data['variety'];
      data['silhouetteName'] = globalDataField['silhouetteName'];
    }
    data['variety'] ??= data['type'];
    data['cost'] ??= 0;
    data['stock'] ??= 0;
    if (data['type'] == 'Mat') data['cutaway'] = data['cutaway'] ?? 0.1;
    return Item.fromJson(data).copyWith(id: snapshot.id);
  }

  factory Item.fromRecipe(BuildContext context, Recipe recipe) {
    return Item(
      id: recipe.id,
      itemId: recipe.id,
      name: recipe.name,
      type: recipe.type,
      variety: recipe.variety,
      unit: recipe.unit,
      size: recipe.size,
      cost: RecipeUtil.getRecipeCost(context, recipe),
      stock: 0,
      itemsV2: recipe.itemsV2,
    );
  }
}
