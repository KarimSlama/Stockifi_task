// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Utils
import '../utils/parse_util.dart';

// Generated Files
part 'global_item.freezed.dart';
part 'global_item.g.dart';

@freezed
class GlobalItem with _$GlobalItem {
  factory GlobalItem({
    required String id,
    required String name,
    @JsonKey(fromJson: ParseUtil.toInt) required int size,
    required String unit,
    required String type,
    required String variety,
  }) = _GlobalItem;

  factory GlobalItem.fromJson(Map<String, dynamic> json) =>
      _$GlobalItemFromJson(json);

  factory GlobalItem.fromSnapshot(DocumentSnapshot snapshot) =>
      GlobalItem.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
