// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

// Generated Files
part 'count_item.freezed.dart';
part 'count_item.g.dart';

@freezed
class CountItem with _$CountItem {
  factory CountItem({
    String? id,
    required String countId,
    required String itemId,
    required String areaId,
    @JsonKey(fromJson: ParseUtil.toDouble) @Default(0.0) double quantity,
    @JsonKey(fromJson: ParseUtil.toDouble) @Default(0.0) double extra,
    @JsonKey(fromJson: ParseUtil.toInt) @Default(0) int updated,
    required String calc,
    Map<String, dynamic>? items,
    @Default(false) bool isPerKilo,
    @Default(false) bool isCorrectCount,
    @JsonKey(fromJson: ParseUtil.toNum) @Default(0) num cost,
  }) = _CountItem;

  factory CountItem.fromJson(Map<String, dynamic> json) =>
      _$CountItemFromJson(json);

  factory CountItem.fromSnapshot(DocumentSnapshot snapshot) =>
      CountItem.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
