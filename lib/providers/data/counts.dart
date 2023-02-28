import 'dart:async';

import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/report_item.dart';
import 'package:stocklio_flutter/providers/data/auth.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import '../../models/count.dart';
import '../../services/count_service.dart';
import '../../utils/logger_util.dart';

class CountProvider with ChangeNotifier {
  late CountService _countService;
  AuthProvider? auth;

  CountProvider({
    this.auth,
    CountService? countService,
  }) {
    auth?.user;
    _countService = GetIt.instance<CountService>();
  }

  List<Count> _counts = [];
  StreamSubscription<List<Count>>? _countsSub;
  Count? _selectedCount;
  Count? _recentlyCompletedCount;
  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;
  Count? get selectedCount => _selectedCount;
  Count? get recentlyCompletedCount => _recentlyCompletedCount;

  List<Count> get counts {
    try {
      _countsSub ?? _listenToCountsStream();
      logger.i('CountProvider - get counts is successful');
    } catch (e, s) {
      logger.e('CountProvider - get counts failed\n$e\n$s');
    }
    return [..._counts];
  }

  Count? getPreviousCount(String currentCountId) {
    final x = _counts.indexWhere((e) => e.id == currentCountId);
    return x == -1 || _counts.length < x + 2 ? null : _counts[x + 1];
  }

  void selectCount(countId) {
    _selectedCount = findById(countId);
    notifyListeners();
  }

  void setSelectedCount(String countId) {
    _selectedCount = _counts.firstWhere((element) => element.id == countId);
    notifyListeners();
  }

  List<Count> get completedCounts {
    var tempCounts = <Count>[];
    try {
      tempCounts = [
        ..._counts
            .where((count) => count.state == 'complete' && count.report != null)
            .toList()
      ];
      if (_recentlyCompletedCount != null &&
          _recentlyCompletedCount!.id != tempCounts.first.id) {
        _selectedCount = null;
      }
      _recentlyCompletedCount = tempCounts.first;
      logger.i('CountProvider - get completedCounts is successful');
    } catch (error, stackTrace) {
      logger
          .e('CountProvider - get completedCounts failed $error\n$stackTrace');
      SentryUtil.error(
          'CountProvider.completedCounts error: tempCounts $tempCounts',
          'CountProvider class',
          error,
          stackTrace);
    }

    return tempCounts;
  }

  Future<void>? cancelStreamSubscriptions() {
    return _countsSub?.cancel();
  }

  void _listenToCountsStream() {
    final user = auth?.user;
    if (user == null) {
      _counts = [];
      return;
    }

    _countsSub = _countService.getCountsStream().listen(
      (List<Count> counts) {
        _counts = counts;
        if (!_isInit) {
          _isInit = true;
          _isLoading = false;
        }
        logger.i(
            'CountProvider - _listenToCountsStream is successful ${counts.length}');
        notifyListeners();
      },
      onError: (e) {
        logger.e('CountProvider - _listenToCountsStream failed\n$e');
      },
    );
  }

  void toggleIsLoading() {
    _isLoading = !_isLoading;
    notifyListeners();
  }

  Future<Map<String, List<ReportItem>>?> getCountReport(String countId) async {
    try {
      final response = await _countService.getCountReport(countId);

      logger.i('CountProvider - getCountReport is successful');

      return response.data;
    } catch (error, stackTrace) {
      logger.e('CountProvider - getCountReport failed\n$error\n$stackTrace');
      SentryUtil.error('CountProvider.getCountReport error: Count $countId',
          'CountProvider class', error, stackTrace);
    }

    return null;
  }

  Future<String> createCount(Count count) async {
    try {
      await _countService.createCount(count);

      logger.i('CountProvider - createCount is successful');
      return 'Count successfully created';
    } catch (error, stackTrace) {
      logger.e('CountProvider - createCount failed\n$error\n$stackTrace');
      SentryUtil.error('CountProvider.createCount error: Count $count',
          'CountProvider class', error, stackTrace);
      return error.toString();
    }
  }

  Future<void> updateCount(Count count) async {
    try {
      await _countService.updateCount(count);

      logger.i('CountProvider - updateCount is successful');
    } catch (error, stackTrace) {
      logger.e('CountProvider - updateCount failed\n$error\n$stackTrace');
      SentryUtil.error('CountProvider.updateCount error: Count $count',
          'CountProvider class', error, stackTrace);
    }
  }

  Future<void> lockCount(Count count) async {
    try {
      await _countService.lockCount(count);

      logger.i('CountProvider - lockCount is successful');
    } catch (error, stackTrace) {
      logger.e('CountProvider - lockCount failed\n$error\n$stackTrace');
      SentryUtil.error('CountProvider.lockCount error: Count $count',
          'CountProvider class', error, stackTrace);
    }
  }

  Future<void> updateCountStateToPending(Count count) async {
    try {
      await _countService.updateCount(count.copyWith(state: 'pending'));

      logger.i('CountProvider - updateCountStateToPending is successful');
    } catch (error, stackTrace) {
      logger.e(
          'CountProvider - updateCountStateToPending failed\n$error\n$stackTrace');
      SentryUtil.error(
          'CountProvider.updateCountStateToPending error: Count $count',
          'CountProvider class',
          error,
          stackTrace);
    }
  }

  Future<void> updateCountStateToStarted(Count count) async {
    try {
      await _countService.updateCount(count.copyWith(state: 'started'));

      logger.i('CountProvider - updateCountStateToStarted is successful');
    } catch (error, stackTrace) {
      logger.e(
          'CountProvider - updateCountStateToStarted failed\n$error\n$stackTrace');
      SentryUtil.error(
          'CountProvider.updateCountStateToStarted error: Count $count',
          'CountProvider class',
          error,
          stackTrace);
    }
  }

  Future<void> softDeleteCount(String countId) async {
    try {
      await _countService.softDeleteCount(countId);

      logger.i('CountProvider - softDeleteCount is successful $countId');
    } catch (error, stackTrace) {
      logger.e('CountProvider - softDeleteCount failed\n$error\n$stackTrace');
      SentryUtil.error('CountProvider.softDeleteCount error: Count ID $countId',
          'CountProvider class', error, stackTrace);
    }
  }

  Count? findStartedOrPendingCount() {
    return _counts.firstWhereOrNull(
        (count) => count.state == 'started' || count.state == 'pending');
  }

  Count? findStartedCount() {
    return _counts.firstWhereOrNull((count) => count.state == 'started');
  }

  Count? findPendingCount() {
    return _counts.firstWhereOrNull((count) => count.state == 'pending');
  }

  Count? findById(String countId) {
    return _counts.firstWhereOrNull((count) => count.id == countId);
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}
