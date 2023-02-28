import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/models/task.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

import '../utils/logger_util.dart';

abstract class TaskService {
  Stream<List<Task>> getTasksStream();
  Future<Response<String?>> createTask(Task task);
  Future<Response<String?>> updateTask(Task task);
  Future<Response<String?>> softDeleteTask(String taskId);
}

class TaskServiceImpl implements TaskService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  TaskServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Future<Response<String?>> createTask(Task task) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/tasks').doc();

      task = task.copyWith(
        id: docRef.id,
        path: '${task.path}?taskId=${docRef.id}',
      );

      var requestBody = task.toJson();
      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;

      await docRef.set(requestBody);

      data = docRef.id;
      logger.i('TaskService - createTask is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('TaskService - createTask failed\n$error\n$stackTrace');
      SentryUtil.error('TaskService.createTask error: Task  $task',
          'TaskService class', error, stackTrace);
    }

    return Response(hasError: hasError, data: data, message: '');
  }

  @override
  Future<Response<String?>> updateTask(Task task) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef =
          _firestore.collection('users/$uid/tasks').doc('${task.id}');

      var requestBody = task.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;

      await docRef.update(requestBody);

      data = docRef.id;
      logger.i('TaskService - updateTask is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('TaskService - updateTask failed\n$error\n$stackTrace');
      SentryUtil.error('TaskService.updateTask error: Task  $task',
          'TaskService class', error, stackTrace);
    }

    return Response(hasError: hasError, data: data, message: '');
  }

  @override
  Stream<List<Task>> getTasksStream() {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/tasks')
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Task.fromSnapshot(doc)).toList();
      }
      return <Task>[];
    });
  }

  @override
  Future<Response<String?>> softDeleteTask(String taskId) async {
    var hasError = false;
    String? data;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/tasks/$taskId');

      var requestBody = {
        'deleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(requestBody);

      data = docRef.id;
      logger.i('TaskService - softDeleteTask is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('TaskService - softDeleteTask failed\n$error\n$stackTrace');
      SentryUtil.error('TaskService.softDeleteTask error: Task ID  $taskId',
          'TaskService class', error, stackTrace);
    }

    return Response(message: '', data: data, hasError: hasError);
  }
}

class MockTaskService implements TaskService {
  @override
  Future<Response<String?>> createTask(Task task) {
    return Future.value(Response(data: 'created'));
  }

  @override
  Future<Response<String?>> updateTask(Task task) {
    return Future.value(Response(data: 'updated'));
  }

  @override
  Stream<List<Task>> getTasksStream() {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> softDeleteTask(String taskId) {
    return Future.value(Response(data: '1'));
  }
}
