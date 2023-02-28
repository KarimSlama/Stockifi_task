// 3rd-Party Packages
import 'dart:convert';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/models/report_item.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

// Generated Files
part 'count.freezed.dart';
part 'count.g.dart';

@freezed
class Count with _$Count {
  factory Count({
    String? id,
    int? sortKey,
    int? endTime,
    int? startTime,
    String? state,
    @JsonKey(fromJson: decodeReports, toJson: encodeReports) dynamic report,
    @JsonKey(fromJson: decodeReports, toJson: encodeReports) dynamic areaReport,
    dynamic variance,
    dynamic costsReport,
    String? varianceReport,
    num? costPercentage,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? initialLockDate,
    @Default(true) bool locked,
    @Default(false) bool stockDownloaded,
    @Default(false) bool varianceDownloaded,
  }) = _Count;

  factory Count.fromJson(Map<String, dynamic> json) => _$CountFromJson(json);

  factory Count.fromSnapshot(DocumentSnapshot snapshot) =>
      Count.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}

List<ReportItem> decodeReports(String? jsonString) {
  if (jsonString == null) return <ReportItem>[];
  var data = jsonDecode(jsonString) as List;
  return data.map((e) => ReportItem.fromJson(e)).toList();
}

dynamic encodeReports(dynamic report) {
  if (report == null) return null;
  return jsonEncode(report);
}
