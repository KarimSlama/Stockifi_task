// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/count_item.dart';

// Services
import '../models/response.dart';
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';

abstract class CountItemService {
  Stream<List<CountItem>> getCountItemsStream(String countId);
  Future<Response<String?>> createCountItem(CountItem countItem);
  Future<Response<String?>> updateCountItem(CountItem countItem);
  Future<Response<String?>> deleteCountItem(String id);
}

class CountItemServiceImpl implements CountItemService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  CountItemServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<CountItem>> getCountItemsStream(String countId) {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/countItems')
        .where('countId', isEqualTo: countId)
        .orderBy('updated', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          // return toPreciseDecimal(CountItem.fromSnapshot(doc));
          return CountItem.fromSnapshot(doc);
        }).toList();
      }
      return <CountItem>[];
    });
  }

  @override
  Future<Response<String?>> createCountItem(CountItem countItem) async {
    var hasError = false;
    String? newCountItemId;

    // final countItemPrecise = toPreciseDecimal(countItem);

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/countItems').doc();

      // var requestBody = countItemPrecise.toJson();
      var requestBody = countItem.toJson();

      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);

      newCountItemId = docRef.id;

      logger.i('CountItemService - createCountItem is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger
          .e('CountItemService - createCountItem failed \n$error\n$stackTrace');
      SentryUtil.error(
          'CountItemService.createCountItem() error: CountItem $countItem',
          'CountItemService class',
          error,
          stackTrace);
    }

    return Response(data: newCountItemId, hasError: hasError);
  }

  @override
  Future<Response<String?>> updateCountItem(CountItem countItem) async {
    String? data;
    var hasError = false;

    // final countItemPrecise = toPreciseDecimal(countItem);

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/countItems/${countItem.id}');

      // var requestBody = countItemPrecise.toJson();
      var requestBody = countItem.toJson();

      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);

      data = docRef.id;

      logger.i(
          'CountItemService - updateCountItem is successful ${countItem.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'CountItemService - updateCountItem failed ${countItem.id}\n$error\n$stackTrace');
      SentryUtil.error(
          'CountItemService.updateCountItem() error: CountItem $countItem',
          'CountItemService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> deleteCountItem(String id) async {
    String? data;
    var hasError = false;
    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/countItems/$id');

      await docRef.delete();

      data = docRef.id;

      logger.i('CountItemService - deleteCountItem is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'CountItemService - deleteCountItem failed $id\n$error\n$stackTrace');
      SentryUtil.error(
          'CountItemService.deleteCountItem() error: CountItem ID $id',
          'CountItemService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  // CountItem toPreciseDecimal(CountItem countItem) {
  //   final countItemQuantity = countItem.quantity;
  //   final countItemExtra = countItem.extra;
  //   final countItemCost = countItem.cost;

  //   final countItemQuantityPrecise = countItemQuantity.toPrecision(2);
  //   final countItemExtraPrecise = countItemExtra.toPrecision(2);
  //   final countItemCostPrecise = countItemCost.toDouble().toPrecision(2);

  //   final countItemPrecise = countItem.copyWith(
  //     quantity: countItemQuantityPrecise,
  //     extra: countItemExtraPrecise,
  //     cost: countItemCostPrecise,
  //   );
  //   return countItemPrecise;
  // }
}

class MockCountItemService implements CountItemService {
  @override
  Future<Response<String?>> createCountItem(CountItem countItem) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> deleteCountItem(String id) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<CountItem>> getCountItemsStream(String countId) {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> updateCountItem(CountItem countItem) {
    return Future.value(Response(data: '1'));
  }
}
