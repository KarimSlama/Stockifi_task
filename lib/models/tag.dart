// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/parse_util.dart';

// Generated Files
part 'tag.freezed.dart';
part 'tag.g.dart';

@freezed
class Tag with _$Tag {
  factory Tag({
    String? id,
    required String name,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
  }) = _Tag;

  factory Tag.fromJson(Map<String, dynamic> json) => _$TagFromJson(json);

  factory Tag.fromSnapshot(DocumentSnapshot snapshot) =>
      Tag.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
