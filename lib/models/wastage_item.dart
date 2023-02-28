// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

// Generated Files
part 'wastage_item.freezed.dart';
part 'wastage_item.g.dart';

@freezed
class WastageItem with _$WastageItem {
  factory WastageItem({
    String? id,
    required String wastageId,
    required String itemId,
    Map<String, dynamic>? items,
    @JsonKey(fromJson: ParseUtil.toDouble) @Default(0.0) double quantity,
    @JsonKey(fromJson: ParseUtil.toNum) @Default(0) num cost,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
    @Default(false) bool isPerKilo,
  }) = _WastageItem;

  factory WastageItem.fromJson(Map<String, dynamic> json) =>
      _$WastageItemFromJson(json);

  factory WastageItem.fromSnapshot(DocumentSnapshot snapshot) =>
      WastageItem.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
