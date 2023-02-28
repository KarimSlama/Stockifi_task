import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/notification.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/notification_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late NotificationService notificationService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();

    // A MockFirebaseAuth instance
    final firebaseAuth = MockFirebaseAuth();

    // Mocks of admin service and organization service
    final AdminService adminService = MockAdminService();
    final OrganizationService organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    final authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );

    notificationService = NotificationServiceImpl(
      firestore: firestore,
      authService: authService,
    );
  });

  test('Notification should be created', () async {
    final notification = StockifiNotification(title: 'Test Notification');

    final response = await notificationService.createNotification(notification);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Notification should be updated', () async {
    final notification = StockifiNotification(title: 'Test Notification');
    var notificationData =
        await notificationService.createNotification(notification);

    final newNotif = StockifiNotification(
        id: notificationData.data, title: 'New Notification');

    final response = await notificationService.updateNotification(newNotif);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Notification should be soft deleted', () async {
    final notification = StockifiNotification(title: 'Test Notification');
    var notificationData =
        await notificationService.createNotification(notification);

    final response = await notificationService
        .softDeleteNotification(notificationData.data!);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
