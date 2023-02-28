// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:freezed_annotation/freezed_annotation.dart';

import '../utils/parse_util.dart';

// Generated Files
part 'task.freezed.dart';
part 'task.g.dart';

enum TaskType {
  defaultTask,
  zeroCostItem,
  updatedPosItem,
  sendItemRequest,
  receiveItemRequest
}

TaskType taskTypeFromJson(dynamic value) {
  final taskTypeList =
      TaskType.values.map((taskType) => taskType.name).toList();
  if (taskTypeList.contains(value)) {
    return TaskType.values.byName(value);
  }
  return TaskType.defaultTask;
}

@freezed
class Task with _$Task {
  factory Task({
    String? id,
    required String title,
    @Default('') String path,
    @JsonKey(fromJson: taskTypeFromJson) required TaskType type,
    @Default({}) Map<String, dynamic> data,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? updatedAt,
    @JsonKey(fromJson: ParseUtil.dateTimeFromTimestamp, toJson: ParseUtil.timestampToDateTime)
        DateTime? createdAt,
  }) = _Task;

  factory Task.fromJson(Map<String, dynamic> json) => _$TaskFromJson(json);

  factory Task.fromSnapshot(DocumentSnapshot snapshot) =>
      Task.fromJson(snapshot.data() as Map<String, dynamic>)
          .copyWith(id: snapshot.id);
}
