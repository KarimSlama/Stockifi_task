// Flutter Packages
import 'dart:async';
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../../models/count_item.dart';

// Services
import '../../services/count_item_service.dart';

// Utils
import '../../utils/logger_util.dart';

class CountItemProvider with ChangeNotifier {
  late CountItemService _countItemService;

  CountItemProvider({
    CountItemService? countItemService,
  }) {
    _countItemService = countItemService ?? GetIt.instance<CountItemService>();
  }

  // States
  final Map<String, List<CountItem>> _countItems = {};
  final Map<String, StreamSubscription> _countItemsSubs = {};
  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;

  List<CountItem> getCountItems(String countId) {
    try {
      _countItemsSubs[countId] ?? _listenToCountItemsStream(countId);
      if (_countItems.containsKey(countId)) {
        return [..._countItems[countId]!];
      }
    } catch (error, stackTrace) {
      logger.e('CountItemProvider - getCountItems failed\n$error');

      SentryUtil.error(
          'CountItemProvider.getCountItems() error: countId $countId',
          'CountItemProvider class',
          error,
          stackTrace);
    }
    return [];
  }

  List<CountItem> getCountItemsByCountAreaId(String countId, String areaId) {
    try {
      _countItemsSubs[countId] ?? _listenToCountItemsStream(countId);
      if (_countItems.containsKey(countId)) {
        return _countItems[countId]!
            .where((element) => element.areaId == areaId)
            .toList();
      }
    } catch (error, stackTrace) {
      logger.e(
          'CountItemProvider - getCountItemsByCountAreaId countId $countId areaId $areaId failed $error');

      SentryUtil.error(
          'CountItemProvider.getCountItemsByCountAreaId() error: countId $countId areaId $areaId',
          'CountItemProvider class',
          error,
          stackTrace);
    }
    return [];
  }

  List<String> getCountItemsWithZeroCost(String countId) {
    var itemIds = <String>[];
    if (_countItems.containsKey(countId)) {
      itemIds = _countItems[countId]!
          .where((element) => element.cost == 0)
          .map((e) => e.itemId)
          .toList();
    }

    return itemIds;
  }

  CountItem? findById(String countId, String id) {
    if (_countItems.containsKey(countId)) {
      return _countItems[countId]!
          .firstWhere((countItem) => countItem.id == id);
    }

    return null;
  }

  Future<List<void>> cancelStreamSubscriptions() {
    final futures = <Future>[];
    for (var subscription in _countItemsSubs.values) {
      futures.add(subscription.cancel());
    }
    return Future.wait(futures);
  }

  void _listenToCountItemsStream(String countId) {
    final countItemStream = _countItemService.getCountItemsStream(countId);

    final countItemsSub = countItemStream.listen((List<CountItem> countItems) {
      if (_countItems.containsKey(countId)) {
        _countItems[countId] = countItems;
      } else {
        _countItems.putIfAbsent(countId, () => countItems);
      }

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });

    _countItemsSubs.putIfAbsent(countId, () => countItemsSub);
  }

  Future<String> createCountItem(CountItem countItem) async {
    try {
      await _countItemService.createCountItem(countItem);

      logger.i('CountItemProvider - createCountItem is successful');
      return 'Item successfully created.';
    } catch (error, stackTrace) {
      logger
          .e('CountItemProvider - createCountItem failed\n$error\n$stackTrace');

      SentryUtil.error(
        'CountItemProvider.createCountItem() error: CountItem $countItem',
        'CountItemProvider class',
        error,
        stackTrace,
      );

      return error.toString();
    }
  }

  Future<String> updateCountItem(
    String id,
    CountItem countItem,
  ) async {
    try {
      await _countItemService.updateCountItem(countItem);

      logger.i('CountItemProvider - createCountItem is successful');
      return 'Item successfully updated.';
    } catch (error, stackTrace) {
      logger
          .e('CountItemProvider - createCountItem failed\n$error\n$stackTrace');

      SentryUtil.error(
          'CountItemProvider.updateCountItem() error: CountItem $countItem',
          'CountItemProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }

  Future<String> deleteCountItem(String id) async {
    try {
      await _countItemService.deleteCountItem(id);

      logger.i('CountItemProvider - deleteCountItem is successful');
      return 'Item successfully deleted.';
    } catch (error, stackTrace) {
      logger
          .e('CountItemProvider - deleteCountItem failed\n$error\n$stackTrace');

      SentryUtil.error(
          'CountItemProvider.deleteCountItem() error: CountItem ID $id',
          'CountItemProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }

  CountItem findByIdAndCountId(String countId, String id) {
    return _countItems[countId]!.firstWhere((element) => element.id == id);
  }

  bool isItemOrRecipeInCount(String? countId, String? itemId) {
    final index =
        _countItems[countId]?.indexWhere((element) => element.itemId == itemId);

    return index != null && index >= 0;
  }

  List<CountItem> getCountItemsByItemId(String countId, String itemId) {
    final countItems =
        getCountItems(countId).where((e) => e.itemId == itemId).toList();

    return countItems;
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }

  // UI States
  List<Offset> silhouettePoints = [];
  double silhouetteHeight = 0.0;
  String selectedItemId = '';
}
