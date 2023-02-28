import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/report_item.dart';

class ReportItemExpandedProvider with ChangeNotifier {
  final List<Map<String, bool>> _expandedReportItems = List.of({});

  List<Map<String, bool>> get expandedReportItems => _expandedReportItems;

  void setExpandedReportItems(List<ReportItem> reportItems) {
    for (var element in reportItems) {
      _expandedReportItems.add({element.id!: false});
    }
  }

  void toggleReportItemExpanded(String reportItemId, bool value) {
    for (var reportItemMap in _expandedReportItems) {
      if (reportItemMap.containsKey(reportItemId)) {
        reportItemMap[reportItemId] = value;
      }
    }
    notifyListeners();
  }

  bool? getReportItemExpanded(String reportItemId) {
    for (var reportItemMap in _expandedReportItems) {
      if (reportItemMap.containsKey(reportItemId)) {
        return reportItemMap[reportItemId]!;
      }
    }
    return null;
  }
}
