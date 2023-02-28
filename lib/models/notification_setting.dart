// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/parse_util.dart';

// Generated Files
part 'notification_setting.freezed.dart';
part 'notification_setting.g.dart';

@freezed
class NotificationSetting with _$NotificationSetting {
  factory NotificationSetting({
    String? id,
    @Default([]) List<Map<String, dynamic>> deviceTokens,
    @Default(false) bool isNotificationsOn,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
  }) = _NotificationSetting;

  factory NotificationSetting.fromJson(Map<String, dynamic> json) =>
      _$NotificationSettingFromJson(json);

  factory NotificationSetting.fromSnapshot(DocumentSnapshot snapshot) =>
      NotificationSetting.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
