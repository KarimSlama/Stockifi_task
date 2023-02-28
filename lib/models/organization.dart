// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Generated Files
part 'organization.freezed.dart';
part 'organization.g.dart';

@freezed
class Organization with _$Organization {
  factory Organization({
    String? id,
    String? name,
    String? email,
    bool? showLockDateOnReport,
  }) = _Organization;

  factory Organization.fromJson(Map<String, dynamic> json) =>
      _$OrganizationFromJson(json);

  factory Organization.fromSnapshot(DocumentSnapshot snapshot) =>
      Organization.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
