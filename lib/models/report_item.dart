import 'package:freezed_annotation/freezed_annotation.dart';

// Generated Files
part 'report_item.freezed.dart';
part 'report_item.g.dart';

@freezed
class ReportItem with _$ReportItem {
  factory ReportItem({
    String? id,
    String? name,
    num? size,
    String? unit,
    String? type,
    String? variety,
    num? cost,
    num? quantity,
    num? extra,
    bool? deleted,
    String? areaId,
    String? areaName,
    String? sortReport,
  }) = _ReportItem;

  factory ReportItem.fromJson(Map<String, dynamic> json) =>
      _$ReportItemFromJson(json);
}
