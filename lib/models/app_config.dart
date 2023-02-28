// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

// Generated Files
part 'app_config.freezed.dart';
part 'app_config.g.dart';

@freezed
class AppConfig with _$AppConfig {
  factory AppConfig({
    @Default(false) bool maintenance,
    @Default(false) bool stockDownload,
    @Default(false) bool varianceDownload,
    @Default(5) int toastDuration,
    @Default(1) int suggestionsDepth,
    @Default(324) int version,
  }) = _AppConfig;

  factory AppConfig.fromJson(Map<String, dynamic> json) =>
      _$AppConfigFromJson(json);

  factory AppConfig.fromSnapshot(DocumentSnapshot snapshot) =>
      AppConfig.fromJson(snapshot.data() as Map<String, dynamic>);
}
