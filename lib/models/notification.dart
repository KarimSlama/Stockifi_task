// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Utils
import '../utils/parse_util.dart';

// Generated Files
part 'notification.freezed.dart';
part 'notification.g.dart';

@freezed
class StockifiNotification with _$StockifiNotification {
  factory StockifiNotification({
    String? id,
    String? title,
    String? body,
    String? imageUrl,
    String? path,
    Map<String, dynamic>? data,
    @Default(false) bool isDismissed,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
  }) = _StockifiNotification;

  factory StockifiNotification.fromJson(Map<String, dynamic> json) =>
      _$StockifiNotificationFromJson(json);

  factory StockifiNotification.fromSnapshot(DocumentSnapshot snapshot) =>
      StockifiNotification.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
