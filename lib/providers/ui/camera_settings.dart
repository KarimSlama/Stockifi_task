import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

///This provider will enable the feature for showing camera preview
///as first element in search items. Setting the [_isCameraEnabled] to true
///will enable this feature

class CameraSettingsProvider with ChangeNotifier {
  bool _isCameraEnabled = false;

  bool get isCameraEnabled => _isCameraEnabled;

  void setIsCameraEnabled(bool value) {
    _isCameraEnabled = value;
    notifyListeners();
  }
}
