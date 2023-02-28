import 'package:flutter/material.dart';

class FileUploadProvider with ChangeNotifier {
  bool _isUploading = false;

  bool get isUploading {
    return _isUploading;
  }

  set isUploading(bool value) {
    _isUploading = value;
    notifyListeners();
  }
}
