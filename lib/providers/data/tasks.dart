import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/services/task_service.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import '../../models/task.dart';
import '../../utils/logger_util.dart';

class TaskProvider extends ChangeNotifier {
  late TaskService _taskService;

  TaskProvider({
    TaskService? taskService,
  }) {
    _taskService = GetIt.instance<TaskService>();
  }

  List<Task> _tasks = [];
  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;

  StreamSubscription<List<Task>>? _tasksSub;

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }

  List<Task> get tasks {
    try {
      _tasksSub ?? _listenToTasksStream();
      logger.i('TaskProvider - get tasks is successful');
    } catch (error, stackTrace) {
      logger.e('TaskProvider - get tasks failed\n$error\n$stackTrace');
      SentryUtil.error('TaskProvider get tasks error!', 'TaskProvider class',
          error, stackTrace);
    }
    return [..._tasks];
  }

  Future<void>? cancelStreamSubscriptions() {
    return _tasksSub?.cancel();
  }

  Future<void> createTask({
    required TaskType type,
    required String title,
    required String path,
    required Map<String, dynamic> data,
  }) async {
    final existingTask = findTask(
      type: type,
      title: title,
      path: path,
      data: data,
    );

    if (existingTask != null) return;

    final newTask = Task(
      type: type,
      title: title,
      path: path,
      data: data,
    );

    try {
      await _taskService.createTask(newTask);

      logger.i('TaskProvider - createTask is successful');
    } catch (error, stackTrace) {
      logger.e('TaskProvider - createTask failed\n$error\n$stackTrace');
      SentryUtil.error('TaskProvider.createTask error: Task $newTask',
          'TaskProvider class', error, stackTrace);
    }
  }

  Future<void> updateTask({
    required TaskType type,
    required String title,
    required String path,
    required Map<String, dynamic> data,
  }) async {
    var taskToUpdate = findTask(
      type: type,
      title: title,
      path: path,
      data: data,
    );

    final updatedTask = taskToUpdate!.copyWith(title: title);

    try {
      await _taskService.updateTask(updatedTask);

      logger.i('TaskProvider - updateTask is successful');
    } catch (error, stackTrace) {
      logger.e('TaskProvider - updateTask failed\n$error\n$stackTrace');
      SentryUtil.error('TaskProvider.updateTask error: Task $updatedTask',
          'TaskProvider class', error, stackTrace);
    }
  }

  Future<void> softDeleteTask({
    String? taskId,
    TaskType? type,
    String? title,
    String? path,
    Map<String, dynamic>? data,
  }) async {
    final task = findTask(
      taskId: taskId,
      type: type,
      title: title,
      path: path,
      data: data,
    );
    try {
      if (task == null) return;
      await _taskService.softDeleteTask(task.id!);
      logger.i('TaskProvider - softDeleteTask is successful');
    } catch (error, stackTrace) {
      logger.e('TaskProvider - softDeleteTask failed\n$error\n$stackTrace');
      SentryUtil.error('TaskProvider.softDeleteTask error: Task ID ${task?.id}',
          'TaskProvider class', error, stackTrace);
    }
  }

  void _listenToTasksStream() {
    _tasksSub = _taskService.getTasksStream().listen(
      (List<Task> tasks) {
        _tasks = tasks;
        if (!_isInit) {
          _isInit = true;
          _isLoading = false;
        }
        logger.i(
            'TaskProvider - _listenToTasksStream is successful ${tasks.length}');
        notifyListeners();
      },
      onError: (e) {
        logger.e('TaskProvider - _listenToTasksStream failed\n$e');
      },
    );
  }

  Task? findById(String id) {
    return _tasks.firstWhereOrNull((element) => element.id == id);
  }

  Task? findTask({
    String? taskId,
    TaskType? type,
    String? title,
    String? path,
    Map<String, dynamic>? data,
  }) {
    if (taskId != null) {
      return findById(taskId);
    }

    bool? foundByType;
    bool? foundByTitle;
    bool? foundByPath;
    bool? foundByData;

    return _tasks.firstWhereOrNull((element) {
      if (type != null) {
        foundByType =
            (element.type == type) || (element.type == TaskType.defaultTask);
      }
      if (title != null) foundByTitle = element.title == title;
      if (path != null) foundByPath = element.path.contains(path);
      if (data != null) foundByData = mapEquals(element.data, data);

      return (foundByType ?? true) &&
          (foundByTitle ?? true) &&
          (foundByPath ?? true) &&
          (foundByData ?? true);
    });
  }
}
