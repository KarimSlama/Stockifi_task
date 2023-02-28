// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

// Generated Files
part 'shortcut.freezed.dart';
part 'shortcut.g.dart';

@freezed
class Shortcut with _$Shortcut {
  factory Shortcut({
    String? id,
    required String name,
    required String path,
    @Default([]) List<String> flags,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
  }) = _Shortcut;

  factory Shortcut.fromJson(Map<String, dynamic> json) =>
      _$ShortcutFromJson(json);

  factory Shortcut.fromSnapshot(DocumentSnapshot snapshot) =>
      Shortcut.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
