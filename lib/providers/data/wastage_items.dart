// Flutter Packages
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/material.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/item.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import 'package:uuid/uuid.dart';

// Models
import '../../models/wastage_item.dart';

// Services
import '../../services/wastage_item_service.dart';

// Utils
import '../../utils/logger_util.dart';

class WastageItemProvider with ChangeNotifier {
  late WastageItemService _wastageItemService;

  WastageItemProvider({
    WastageItemService? wastageItemService,
  }) {
    _wastageItemService =
        wastageItemService ?? GetIt.instance<WastageItemService>();
  }

  // States
  final Map<String, List<WastageItem>> _wastageItems = {};
  final Map<String, StreamSubscription> _wastageItemsStreamSubs = {};
  bool _isLoading = true;
  bool _isInit = false;

  bool get isLoading => _isLoading;

  List<WastageItem> getWastageItems(String wastageId) {
    try {
      _wastageItemsStreamSubs[wastageId] ??
          _listenToWastageItemsStream(wastageId);
      if (_wastageItems.containsKey(wastageId)) {
        return [..._wastageItems[wastageId]!];
      }
    } catch (error, stackTrace) {
      logger.e('WastageItemProvider - getWastageItems failed\n$error');

      SentryUtil.error(
          'WastageItemProvider.getWastageItems() error: wastageId $wastageId',
          'WastageItemProvider class',
          error,
          stackTrace);
    }
    return [];
  }

  void _listenToWastageItemsStream(String wastageId) {
    final wastageItemStream =
        _wastageItemService.getWastageItemsStream(wastageId);

    final wastageItemsSub =
        wastageItemStream.listen((List<WastageItem> wastageItems) {
      if (_wastageItems.containsKey(wastageId)) {
        _wastageItems[wastageId] = wastageItems;
      } else {
        _wastageItems.putIfAbsent(wastageId, () => wastageItems);
      }

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });

    _wastageItemsStreamSubs.putIfAbsent(wastageId, () => wastageItemsSub);
  }

  WastageItem? getWastageItemByItemId(String wastageId, String itemId) {
    return _wastageItems[wastageId]
        ?.firstWhereOrNull((element) => element.itemId == itemId);
  }

  WastageItem? getWastageItemById(String wastageId, String wastageItemId) {
    return _wastageItems[wastageId]
        ?.firstWhereOrNull((element) => element.id == wastageItemId);
  }

  Future<String> createWastageItem(WastageItem wastageItem) async {
    try {
      await _wastageItemService.createWastageItem(wastageItem);

      logger.i('WastageItemProvider - createWastageItem is successful');
      return 'Item successfully created.';
    } catch (error, stackTrace) {
      logger.e(
          'WastageItemProvider - createWastageItem failed\n$error\n$stackTrace');

      SentryUtil.error(
          'WastageItemProvider.createWastageItem() error: WastageItem $wastageItem',
          'WastageItemProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }

  Future<String> updateWastageItem(
    WastageItem wastageItem,
  ) async {
    try {
      await _wastageItemService.updateWastageItem(wastageItem);

      logger.i('WastageItemProvider - createWastageItem is successful');
      return 'Item successfully updated.';
    } catch (error, stackTrace) {
      logger.e(
          'WastageItemProvider - createWastageItem failed\n$error\n$stackTrace');

      SentryUtil.error(
          'WastageItemProvider.updateWastageItem() error: WastageItem $wastageItem',
          'WastageItemProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }

  Future<void> updateWastageItemEntry({
    required String wastageId,
    required num wastageItemEntrySize,
    required Item item,
    String? wastageItemEntryId,
    WastageItem? wastageItem,
    required bool isPerKilo,
  }) async {
    final tempWastageItem = wastageItem ??
        WastageItem(
          wastageId: wastageId,
          itemId: item.id!,
          cost: 0,
          items: {},
          quantity: 0,
          isPerKilo: isPerKilo,
        );

    try {
      final wastageEntries =
          Map<String, dynamic>.from(tempWastageItem.items ?? {});
      if (wastageItemEntrySize == 0) {
        wastageEntries.remove(wastageItemEntryId);

        if (wastageEntries.isEmpty) {
          await deleteWastageItem(wastageId);
        }
      } else {
        if (wastageItemEntryId != null &&
            wastageEntries.containsKey(wastageItemEntryId)) {
          wastageEntries[wastageItemEntryId] = wastageItemEntrySize;
        } else {
          wastageEntries.putIfAbsent(
              const Uuid().v1(), () => wastageItemEntrySize);
        }
      }

      if (wastageItem != null) {
        await updateWastageItem(
            tempWastageItem.copyWith(items: wastageEntries));
      } else {
        await createWastageItem(
            tempWastageItem.copyWith(items: wastageEntries));
      }

      logger.i('WastageItemProvider - deleteWastageItem is successful');
    } catch (error, stackTrace) {
      logger.e(
          'WastageItemProvider - deleteWastageItem failed\n$error\n$stackTrace');

      SentryUtil.error(
          'WastageItemProvider.deleteWastageItem() error: WastageItem ID ${wastageItem?.id}',
          'WastageItemProvider class',
          error,
          stackTrace);
    }
  }

  Future<String> deleteWastageItem(String id) async {
    try {
      final response = await _wastageItemService.deleteWastageItem(id);

      if (!response.hasError) {
        logger.i('WastageItemProvider - deleteWastageItem is successful');
        return 'Wastage item successfully deleted.';
      } else {
        logger.i('WastageItemProvider - deleteWastageItem failed');
        return 'Wastage item not deleted.';
      }
    } catch (error, stackTrace) {
      logger.e(
          'WastageItemProvider - deleteWastageItem failed\n$error\n$stackTrace');

      SentryUtil.error(
          'WastageItemProvider.deleteWastageItem() error: WastageItem ID $id',
          'WastageItemProvider class',
          error,
          stackTrace);

      return error.toString();
    }
  }
}
