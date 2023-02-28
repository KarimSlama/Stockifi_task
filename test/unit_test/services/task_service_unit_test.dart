import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/task.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/services/task_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late TaskService taskService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();

    // Mocks of admin service and organization service
    final adminService = MockAdminService();
    final organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );
    taskService = TaskServiceImpl(
      firestore: firestore,
      authService: authService,
    );
  });

  test('Task should be created', () async {
    final newTask =
        Task(type: TaskType.zeroCostItem, title: 'New Task', path: '/');

    final response = await taskService.createTask(newTask);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Task should be soft deleted', () async {
    var response = await taskService.createTask(
        Task(type: TaskType.zeroCostItem, title: 'New Task', path: '/'));
    response = await taskService.softDeleteTask(response.data!);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
