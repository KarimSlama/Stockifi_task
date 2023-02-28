import 'dart:async';

import 'package:flutter/material.dart';
import 'package:uuid/uuid.dart';

class ToastProvider extends ChangeNotifier {
  final List<Toast> _toastMessages = [];
  final Map<String, Timer> _timers = {};

  List<Toast> get toastMessages => [..._toastMessages];

  bool hasNewToast = false;

  void addToastMessage(String message) {
    final newToast = Toast(id: const Uuid().v1(), message: message);
    _toastMessages.add(newToast);
    hasNewToast = true;
    notifyListeners();
  }

  void removeToast(String toastId) {
    _timers.remove(toastId);
    _toastMessages.removeWhere((element) => element.id == toastId);
    notifyListeners();
  }

  Timer? getToastTimer(String toastId) {
    return _timers[toastId];
  }

  void addToastTimer(String toastId, Timer timer) {
    _timers.putIfAbsent(toastId, () => timer);
  }

  int getToastIndex(String toastId) {
    return _toastMessages.indexWhere((element) => element.id == toastId);
  }
}

class Toast {
  final String id;
  final String message;

  Toast({
    required this.id,
    required this.message,
  });
}
