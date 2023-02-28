// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Utils
import '../utils/parse_util.dart';

// Generated Files
part 'pos_item.freezed.dart';
part 'pos_item.g.dart';

@freezed
class PosItem with _$PosItem {
  factory PosItem({
    String? id,
    @Default({}) Map<String, num> items,
    dynamic posData,
    String? userId,
    @JsonKey(fromJson: ParseUtil.toNum) @Default(0) num cost,
    dynamic costPerItem,
    @Default(false) bool archived,
  }) = _PosItem;

  factory PosItem.fromJson(Map<String, dynamic> json) =>
      _$PosItemFromJson(json);

  factory PosItem.fromSnapshot(DocumentSnapshot snapshot) =>
      PosItem.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
