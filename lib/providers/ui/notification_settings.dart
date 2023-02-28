import 'package:flutter/material.dart';

///This provider will enable the feature for showing notification icon
///and notification badge. Setting the [_isNotificationEnabled] to true
///will enable this feature

class NotificationSettingsProvider with ChangeNotifier {
  bool _isNotificationEnabled = true;

  bool get isNotificationEnabled => _isNotificationEnabled;

  void setIsNotificationEnabled(bool _) {
    _isNotificationEnabled = _;
    notifyListeners();
  }
}
