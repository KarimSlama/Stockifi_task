// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';
import 'package:stocklio_flutter/utils/parse_util.dart';

// Generated Files
part 'profile.freezed.dart';
part 'profile.g.dart';

@freezed
class Profile with _$Profile {
  factory Profile({
    String? id,
    String? name,
    String? email,
    @JsonKey(fromJson: ParseUtil.toInt) @Default(0) int accessLevel,
    @Default('type') String sortReport,
    @Default('eu') String numberFormat,
    @Default('en') String language,
    @Default('NOK') String currencyLong,
    @Default('kr') String currencyShort,
    @Default({}) Map<String, dynamic> customTypes,
    @Default(false) bool customReport,
    @Default({}) Map<String, String> customReportAreas,
    @Default(false) bool differenceReport,
    @Default(false) bool differenceValueReport,
    @Default(false) bool alcoholGroupReport,
    @Default(true) bool summaryDifferenceReport,
    @Default([]) List<Map<String, dynamic>> downloadedReports,
    @Default(false) bool inventoryScreen,
    String? organizationId,
    @Default(false) bool isOnline,
    @Default(false) bool organization,
    @Default(false) bool extraColumnEnabled,
    @Default(false) bool isCameraEnabled,
    @Default(false) bool isWastageEnabled,
    @Default(false) bool isPerKiloEnabled,
    @Default(false) bool isCountReportPreviewEnabled,
    @Default(false) bool isTutorialsEnabled,
    @Default(true) bool isSearchHighlightEnabled,
    @Default(false) bool isItemTagsEnabled,
    @Default(false) bool isLocalizationEnabled,
    @Default(false) bool isRecipeNoteEnabled,
    @Default(false) bool isPosItemsAsMenuItemsEnabled,
    @Default(false) bool isIFrameDashboardEnabled,
    @Default(false) bool isTransferItemsEnabled,
    @Default(false) bool isItemCutawayEnabled,
    bool? hasAnActiveCount,
    @Default(10) int scanRate,
    @Default({}) Map<String, dynamic> tasksCount,
    @Default({}) Map<String, dynamic> invoicesCount,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? lastAPFetch,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? lastPOSFetch,
  }) = _Profile;

  factory Profile.fromJson(Map<String, dynamic> json) =>
      _$ProfileFromJson(json);

  factory Profile.fromSnapshot(DocumentSnapshot snapshot) =>
      Profile.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
