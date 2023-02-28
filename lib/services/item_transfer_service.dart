import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import '../utils/logger_util.dart';

abstract class ItemTransferService {
  Future<Response<void>> createItemTransferRequest(
    String sourceUserName,
    String targetUserId,
    String targetUserName,
    String itemId,
    String itemName,
    int quantity,
  );
  Future<Response<void>> acceptItemTransferRequest(
    String transferId,
    String itemId,
  );
  Future<Response<void>> cancelItemTransferRequest(String transferId);
  Future<Response<dynamic>> getOrganizationUsers(String organizationId);
  Future<Response<dynamic>> editItemTransferRequest(
      String transferId, int quantity);
}

class ItemTransferServiceImpl implements ItemTransferService {
  late final AuthService _authService;
  late final FirebaseFunctions _functions;

  ItemTransferServiceImpl({
    FirebaseFunctions? functions,
    AuthService? authService,
  }) {
    _authService = authService ?? GetIt.instance<AuthService>();
    _functions = functions ?? FirebaseFunctions.instance;
  }

  @override
  Future<Response<void>> createItemTransferRequest(
    String sourceUserName,
    String targetUserId,
    String targetUserName,
    String itemId,
    String itemName,
    int quantity,
  ) async {
    var hasError = false;

    try {
      final uid = _authService.uid;
      await _functions.httpsCallable('users-createItemTransferRequest').call(
        {
          'sourceUserId': uid,
          'sourceUserName': sourceUserName,
          'targetUserId': targetUserId,
          'targetUserName': targetUserName,
          'itemId': itemId,
          'itemName': itemName,
          'quantity': quantity,
        },
      );

      logger.i('ItemTransferService - createItemTransfer is successful');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'ItemTransferService - createItemTransfer failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemTransferService.createItemTransfer error: ItemTransfer',
        'ItemTransferService class',
        error,
        stackTrace,
      );
    }

    return Response(hasError: hasError, message: '');
  }

  @override
  Future<Response<void>> acceptItemTransferRequest(
    String transferId,
    String itemId,
  ) async {
    var hasError = false;

    try {
      await _functions.httpsCallable('users-acceptItemTransferRequest').call(
        {
          'transferId': transferId,
          'itemId': itemId,
        },
      );

      logger.i('ItemTransferService - acceptItemTransferRequest is successful');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'ItemTransferService - acceptItemTransferRequest failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemTransferService.acceptItemTransferRequest error: ItemTransfer',
        'ItemTransferService class',
        error,
        stackTrace,
      );
    }

    return Response(hasError: hasError, message: '');
  }

  @override
  Future<Response<void>> cancelItemTransferRequest(String transferId) async {
    var hasError = false;

    try {
      await _functions.httpsCallable('users-cancelItemTransferRequest').call(
        {
          'transferId': transferId,
        },
      );

      logger.i('ItemTransferService - cancelItemTransferRequest is successful');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'ItemTransferService - cancelItemTransferRequest failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemTransferService.cancelItemTransferRequest error: ItemTransfer',
        'ItemTransferService class',
        error,
        stackTrace,
      );
    }

    return Response(hasError: hasError, message: '');
  }

  @override
  Future<Response<dynamic>> getOrganizationUsers(String organizationId) async {
    var hasError = false;
    dynamic data;

    try {
      final result = await _functions
          .httpsCallable('users-getOrganizationUsers')
          .call({'organizationId': organizationId});

      data = (result.data as List)
          .where((element) => (element['id'] != _authService.uid))
          .toList();

      logger
          .i('ItemTransferService - getOrganizationUsers is successful $data');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'ItemTransferService - getOrganizationUsers failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemTransferService.getOrganizationUsers error: ItemTransfer',
        'ItemTransferService class',
        error,
        stackTrace,
      );
    }

    return Response(hasError: hasError, data: data, message: '');
  }

  @override
  Future<Response> editItemTransferRequest(
      String transferId, int quantity) async {
    var hasError = false;

    try {
      await _functions.httpsCallable('users-editItemTransferRequest').call(
        {'transferId': transferId, 'quantity': quantity},
      );

      logger.i('ItemTransferService - editItemTransferRequest is successful');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'ItemTransferService - editItemTransferRequest failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemTransferService.editItemTransferRequest error: ItemTransfer',
        'ItemTransferService class',
        error,
        stackTrace,
      );
    }

    return Response(hasError: hasError, message: '');
  }
}

class MockItemTransferService implements ItemTransferService {
  @override
  Future<Response<void>> createItemTransferRequest(
    String sourceUserName,
    String targetUserId,
    String targetUserName,
    String itemId,
    String itemName,
    int quantity,
  ) {
    return Future.value(Response(hasError: false, message: ''));
  }

  @override
  Future<Response<void>> acceptItemTransferRequest(
      String transferId, String itemId) {
    return Future.value(Response(hasError: false, message: ''));
  }

  @override
  Future<Response<void>> cancelItemTransferRequest(String transferId) {
    return Future.value(Response(hasError: false, message: ''));
  }

  @override
  Future<Response<dynamic>> getOrganizationUsers(String organizationId) {
    return Future.value(Response(hasError: false, message: ''));
  }

  @override
  Future<Response> editItemTransferRequest(String transferId, int quantity) {
    // TODO: implement editItemTransferRequest
    throw UnimplementedError();
  }
}
