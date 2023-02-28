import 'package:flutter/foundation.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/services/item_transfer_service.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

class ItemTransferProvider extends ChangeNotifier {
  late ItemTransferService _itemTransferService;

  ItemTransferProvider({
    ItemTransferService? itemTransferService,
  }) {
    _itemTransferService = GetIt.instance<ItemTransferService>();
  }

  int _quantity = 0;

  int get quantity => _quantity;

  void setQuantity(int val) {
    _quantity = val;
    notifyListeners();
  }

  void increaseQuantity() {
    _quantity++;
    notifyListeners();
  }

  void decreaseQuantity() {
    if (_quantity != 0) {
      _quantity--;
      notifyListeners();
    }
  }

  void resetQuantity() {
    _quantity = 0;

    notifyListeners();
  }

  Future<List<dynamic>?> getOrganizationUsers(String organizationId) async {
    try {
      final response =
          await _itemTransferService.getOrganizationUsers(organizationId);

      logger.i('ItemTransferProvider - getOrganizationUsers is successful');

      return response.data;
    } catch (error, stackTrace) {
      logger.e(
          'ItemTransferProvider - getOrganizationUsers failed $error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.getOrganizationUsers() error',
        'ItemTransferProvider class',
        error,
        stackTrace,
      );
    }
    return null;
  }

  Future<void> createItemTransferRequest(
    String sourceUserName,
    String targetUserId,
    String targetUserName,
    String itemId,
    String itemName,
    int quantity,
  ) async {
    try {
      final response = await _itemTransferService.createItemTransferRequest(
        sourceUserName,
        targetUserId,
        targetUserName,
        itemId,
        itemName,
        quantity,
      );

      logger
          .i('ItemTransferProvider - createItemTransferRequest is successful');

      return response.data;
    } catch (error, stackTrace) {
      logger.e(
          'ItemTransferProvider - createItemTransferRequest failed $error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.createItemTransferRequest() error',
        'ItemTransferProvider class',
        error,
        stackTrace,
      );
    }
  }

  Future<void> cancelItemTransferRequest(String transferId) async {
    try {
      final response =
          await _itemTransferService.cancelItemTransferRequest(transferId);

      logger
          .i('ItemTransferProvider - cancelItemTransferRequest is successful');

      return response.data;
    } catch (error, stackTrace) {
      logger.e(
          'ItemTransferProvider - cancelItemTransferRequest failed $error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.cancelItemTransferRequest() error',
        'ItemTransferProvider class',
        error,
        stackTrace,
      );
    }
  }

  Future<void> editItemTransferRequest(String transferId, int quantity) async {
    try {
      final response = await _itemTransferService.editItemTransferRequest(
          transferId, quantity);

      logger.i('ItemTransferProvider - editItemTransferRequest is successful');

      return response.data;
    } catch (error, stackTrace) {
      logger.e(
          'ItemTransferProvider - editItemTransferRequest failed $error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.editItemTransferRequest() error',
        'ItemTransferProvider class',
        error,
        stackTrace,
      );
    }
  }

  Future<void> acceptItemTransferRequest(
    String transferId,
    String itemId,
  ) async {
    try {
      final response = await _itemTransferService.acceptItemTransferRequest(
          transferId, itemId);

      logger
          .i('ItemTransferProvider - acceptItemTransferRequest is successful');

      return response.data;
    } catch (error, stackTrace) {
      logger.e(
          'ItemTransferProvider - acceptItemTransferRequest failed $error\n$stackTrace');
      SentryUtil.error(
        'ItemProvider.acceptItemTransferRequest() error',
        'ItemTransferProvider class',
        error,
        stackTrace,
      );
    }
  }
}
