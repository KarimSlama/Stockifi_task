// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

// Generated Files
part 'tutorial.freezed.dart';
part 'tutorial.g.dart';

@freezed
class Tutorial with _$Tutorial {
  factory Tutorial({
    String? id,
    String? name,
    String? title,
    String? description,
    List<String>? media,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
  }) = _Tutorial;

  factory Tutorial.fromJson(Map<String, dynamic> json) =>
      _$TutorialFromJson(json);

  factory Tutorial.fromSnapshot(DocumentSnapshot snapshot) =>
      Tutorial.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
