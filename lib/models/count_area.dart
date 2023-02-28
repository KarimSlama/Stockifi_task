// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Generated Files
part 'count_area.freezed.dart';
part 'count_area.g.dart';

@freezed
class CountArea with _$CountArea {
  factory CountArea({
    String? id,
    required String name,
  }) = _CountArea;

  factory CountArea.fromJson(Map<String, dynamic> json) =>
      _$CountAreaFromJson(json);

  factory CountArea.fromSnapshot(DocumentSnapshot snapshot) =>
      CountArea.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
