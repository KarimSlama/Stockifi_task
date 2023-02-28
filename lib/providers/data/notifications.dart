// Flutter Packages
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';

// Models
import 'package:stocklio_flutter/models/notification.dart';

// Services
import 'package:stocklio_flutter/services/notification_service.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

class NotificationProvider with ChangeNotifier {
  late NotificationService _notificationService;

  NotificationProvider({
    NotificationService? notificationService,
  }) {
    _notificationService =
        notificationService ?? GetIt.instance<NotificationService>();
  }

  // States
  List<StockifiNotification> _notifications = [];
  StreamSubscription<List<StockifiNotification>>? _notificationsStreamSub;
  bool _isLoading = true;
  bool _isInit = false;

  // Getters
  bool get isLoading => _isLoading;
  List<StockifiNotification> get notifications {
    _notificationsStreamSub ?? _listenToNotificationsStream();
    return [..._notifications];
  }

  List<StockifiNotification> get unreadNotifications {
    return [...notifications.where((element) => !element.isDismissed).toList()];
  }

  List<StockifiNotification> get dismissedNotifications {
    return [...notifications.where((element) => element.isDismissed).toList()];
  }

  Future<void>? cancelStreamSubscriptions() {
    return _notificationsStreamSub?.cancel();
  }

  void _listenToNotificationsStream() {
    _notificationsStreamSub =
        _notificationService.getNotificationsStream().listen(
      (List<StockifiNotification> notifications) {
        _notifications = notifications;

        if (_notifications.isNotEmpty) {
          selectedNotificationId = _notifications.first.id!;
        }

        if (!_isInit) {
          _isInit = true;
          _isLoading = false;
        }
        logger.i(
            'NotificationProvider - _listenToNotificationStream is successful ${notifications.length}');

        notifyListeners();
      },
      onError: (error, stackTrace) {
        logger.e(
            'NotificationProvider - _listenToNotificationStream failed\n$error');
        SentryUtil.error(
            'NotificationProvider._listenToNotificationsStream() error!',
            'NotificationProvider class',
            error,
            stackTrace);
      },
    );
  }

  Future<void> createNotification({
    required String title,
    required String body,
    required Map<String, dynamic> data,
    required String path,
  }) async {
    final existingNotification = findUnreadNotification(
      title: title,
      path: path,
    );

    if (existingNotification != null) return;

    final newNotification = StockifiNotification(
      title: title,
      path: path,
      data: data,
      body: body,
    );

    await _notificationService.createNotification(newNotification).whenComplete(
        () => logger.i(
            'NotificationProvider - One Notification successfully created.'));
  }

  Future<void> updateNotification(
    StockifiNotification notification,
    String newTitle,
    String newBody,
  ) async {
    await _notificationService
        .updateNotification(
          notification.copyWith(
            title: newTitle,
            body: newBody,
          ),
        )
        .whenComplete(() => logger.i(
            'NotificationProvider - Notification with id ${notification.id} successfully updated.'));
  }

  Future<void> updateNotificationDeleted(String notificationId) async {
    await _notificationService.softDeleteNotification(notificationId);
  }

  Future<void> setNotificationIsDismissed(
    StockifiNotification notification,
    bool value,
  ) async {
    await _notificationService.updateNotification(
      notification.copyWith(isDismissed: value),
    );
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }

  // UI States
  String _selectedNotificationId = '';

  String get selectedNotificationId => _selectedNotificationId;

  set selectedNotificationId(String notificationId) {
    _selectedNotificationId = notificationId;
    notifyListeners();
  }

  StockifiNotification findNotificationById(String id) {
    return _notifications.firstWhere((element) => element.id == id);
  }

  void markAllNotificationsAsRead(List<StockifiNotification> notifications) {
    for (var notification in notifications) {
      if (!notification.isDismissed) {
        setNotificationIsDismissed(notification, true);
      }
    }
  }

  StockifiNotification? findNotification({
    String? id,
    String? title,
    String? path,
  }) {
    if (id != null) {
      return findNotificationById(id);
    }

    bool? foundByTitle;
    bool? foundByPath;

    return _notifications.firstWhereOrNull((element) {
      if (title != null) foundByTitle = element.title == title;
      if (path != null) foundByPath = element.path?.contains(path);

      return (foundByTitle ?? true) && (foundByPath ?? true);
    });
  }

  StockifiNotification? findUnreadNotification({
    String? id,
    String? title,
    String? path,
  }) {
    if (id != null) {
      return findNotificationById(id);
    }

    bool? foundByTitle;
    bool? foundByPath;

    return unreadNotifications.firstWhereOrNull((element) {
      if (title != null) foundByTitle = element.title == title;
      if (path != null) foundByPath = element.path?.contains(path);

      return (foundByTitle ?? true) && (foundByPath ?? true);
    });
  }
}
