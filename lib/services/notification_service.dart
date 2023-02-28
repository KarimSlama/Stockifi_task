// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

// Models
import 'package:stocklio_flutter/models/notification.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Services
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';

abstract class NotificationService {
  Stream<List<StockifiNotification>> getNotificationsStream();
  Future<Response<String?>> createNotification(
      StockifiNotification notification);
  Future<Response<String?>> updateNotification(
      StockifiNotification notification);
  Future<Response<String?>> softDeleteNotification(String notificationId);
}

class NotificationServiceImpl implements NotificationService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  NotificationServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<StockifiNotification>> getNotificationsStream() {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/notifications')
        .where(
          'createdAt',
          isGreaterThanOrEqualTo: Timestamp.fromDate(
            DateTime.now().subtract(const Duration(days: 62)),
          ),
        )
        .where('deleted', isEqualTo: false)
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs
            .map((doc) => StockifiNotification.fromSnapshot(doc))
            .toList();
      }
      return <StockifiNotification>[];
    });
  }

  @override
  Future<Response<String?>> createNotification(
      StockifiNotification notification) async {
    String? data;
    var hasError = false;
    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/notifications').doc();

      var requestBody = notification.toJson();
      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);

      data = docRef.id;

      logger.i(
          'NotificationService - createNotification is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'NotificationService - createNotification failed\n$error\n$stackTrace');
      SentryUtil.error(
          'NotificationService.createNotification() error: notification $notification',
          'NotificationService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> updateNotification(
      StockifiNotification notification) async {
    String? data;
    var hasError = false;
    try {
      final uid = _authService.uid;
      final docRef =
          _firestore.doc('users/$uid/notifications/${notification.id}');

      var requestBody = notification.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);
      data = docRef.id;

      logger.i(
          'NotificationService - updateNotification is successful ${notification.id}');
    } catch (error, stackTrace) {
      logger.e(
          'NotificationService - updateNotification failed ${notification.id}\n$error\n$stackTrace');
      SentryUtil.error(
          'NotificationService.updateNotification() error: notification $notification',
          'NotificationService class',
          error,
          stackTrace);
    }
    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> softDeleteNotification(
      String notificationId) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/notifications/$notificationId');

      var requestBody = {
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(requestBody);
      data = docRef.id;

      logger.i(
          'NotificationService - deleteNotification is successful $notificationId');
    } catch (error, stackTrace) {
      logger.i(
          'NotificationService - deleteNotification failed $notificationId\n$error\n$stackTrace');
      SentryUtil.error(
          'NotificationService.softDeleteNotification() error: notificationId $notificationId',
          'NotificationService class',
          error,
          stackTrace);
    }
    return Response(data: data, hasError: hasError);
  }
}

class MockNotificationService implements NotificationService {
  @override
  Future<Response<String?>> createNotification(
      StockifiNotification notification) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<StockifiNotification>> getNotificationsStream() {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> softDeleteNotification(String notificationId) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> updateNotification(
      StockifiNotification notification) {
    return Future.value(Response(data: '1'));
  }
}
