import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

part 'wastage.freezed.dart';
part 'wastage.g.dart';

@freezed
class Wastage with _$Wastage {
  factory Wastage({
    String? id,
    String? state,
    int? sortKey,
    int? endTime,
    int? startTime,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? initialLockDate,
    @Default(true) bool locked,
  }) = _Wastage;

  factory Wastage.fromJson(Map<String, dynamic> json) =>
      _$WastageFromJson(json);

  factory Wastage.fromSnapshot(DocumentSnapshot snapshot) =>
      Wastage.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
