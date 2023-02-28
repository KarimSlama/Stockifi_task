// 3rd-Party Packages
import 'package:freezed_annotation/freezed_annotation.dart';

// Generated Files
part 'cloud_storage_result.freezed.dart';

@freezed
class CloudStorageResult with _$CloudStorageResult {
  factory CloudStorageResult({String? downloadUrl, String? fileName}) =
      _CloudStorageResult;
}
