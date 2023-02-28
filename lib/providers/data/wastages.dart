import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/material.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/models/wastage.dart';
import 'package:stocklio_flutter/services/wastage_service.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

class WastageProvider with ChangeNotifier {
  late final WastageService _wastageService;

  WastageProvider({WastageService? wastageService})
      : _wastageService = wastageService ?? GetIt.instance<WastageService>();

  List<Wastage> _wastages = [];
  StreamSubscription<List<Wastage>>? _wastagesStreamSub;
  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;

  List<Wastage> get wastages {
    try {
      _wastagesStreamSub ?? _listenToWastagesStream();
      logger.i('WastageProvider - get wastages is successful');
    } catch (e, s) {
      logger.e('WastageProvider - get wastages failed\n$e\n$s');
    }
    return [..._wastages];
  }

  Wastage? get latestWastage {
    return wastages.firstWhereOrNull(
        (wastage) => wastage.state == 'started' || wastage.state == 'pending');
  }

  Wastage? get lastLockedWastage {
    return wastages.firstWhereOrNull((wastage) => wastage.state == 'locked');
  }

  void _listenToWastagesStream() {
    _wastagesStreamSub = _wastageService
        .getWastagesStream()
        .listen((List<Wastage> wastages) async {
      _wastages = wastages;

      final latestWastage = wastages.firstWhereOrNull((wastage) =>
          wastage.state == 'started' || wastage.state == 'pending');

      if (latestWastage == null) {
        await createWastage();
      }

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  Future<Response<String?>> createWastage() async {
    final currDate = DateTime.now();
    final targetMonth = currDate.month;

    final wastageStartTime = DateTime(currDate.year, targetMonth, 1);
    final wastageEndTime = DateTime(currDate.year, targetMonth + 1, 1);

    final wastage = Wastage(
      startTime: wastageStartTime.millisecondsSinceEpoch,
      endTime: wastageEndTime.millisecondsSinceEpoch,
      locked: false,
      state: 'started',
    );

    try {
      final response = await _wastageService.createWastage(wastage);

      logger.i('WastageProvider - createWastage is successful');
      return response;
    } catch (error, stackTrace) {
      logger.e('WastageProvider - createWastage failed\n$error\n$stackTrace');
      SentryUtil.error('WastageProvider.createWastage error: Wastage $wastage',
          'WastageProvider class', error, stackTrace);
      return Response(hasError: true, data: error.toString());
    }
  }

  Future<void> updateWastage(Wastage wastage) async {
    try {
      await _wastageService.updateWastage(wastage);

      logger.i('WastageProvider - updateWastage is successful');
    } catch (error, stackTrace) {
      logger.e('WastageProvider - updateWastage failed\n$error\n$stackTrace');
      SentryUtil.error('WastageProvider.updateWastage error: Wastage $wastage',
          'WastageProvider class', error, stackTrace);
    }
  }

  Future<void> lockCurrentWastage() async {
    if (latestWastage == null) return;

    try {
      await _wastageService.lockWastage(latestWastage!);
      logger.i('WastageProvider - lockCurrentWastage is successful');
    } catch (error, stackTrace) {
      logger.e(
          'WastageProvider - lockCurrentWastage failed\n$error\n$stackTrace');
      SentryUtil.error(
          'WastageProvider.lockCurrentWastage error: Wastage ${latestWastage!.id}',
          'WastageProvider class',
          error,
          stackTrace);
    }
  }

  Future<void> unlockWastage() async {
    if (lastLockedWastage == null) return;

    try {
      await _wastageService.unlockWastage(lastLockedWastage!);

      logger.i('WastageProvider - unlockWastage is successful');
    } catch (error, stackTrace) {
      logger.e('WastageProvider - unlockWastage failed\n$error\n$stackTrace');
      SentryUtil.error(
          'WastageProvider.unlockWastage error: Wastage ${lastLockedWastage!.id}',
          'WastageProvider class',
          error,
          stackTrace);
    }
  }
}
