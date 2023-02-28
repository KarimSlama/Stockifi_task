// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/item.dart';

// Services
import '../models/response.dart';
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';

abstract class ItemService {
  Stream<List<Item>> getItemsStream({
    String? uid,
    bool isFetchingDeleted = false,
    bool isFetchingArchived = false,
  });
  Stream<Item> getSingleItemById(String itemId,
      {bool isFetchingDeleted = false});
  Future<Response<String?>> createItem(Item item);
  Future<Response<String?>> updateItem(Item item, [String? currentCountId]);
  Future<Response<String?>> updateItemDeletedStatus(Item item,
      {bool deleted = true});
  Future<Response> unStarItems(List<Item> items);
  Future<Response<String>> setArchived(String itemId, bool value);
}

class ItemServiceImpl implements ItemService {
  late FirebaseFirestore _firestore;
  late final AuthService _authService;

  ItemServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<Item>> getItemsStream({
    bool isFetchingDeleted = false,
    bool isFetchingArchived = false,
    String? uid,
  }) {
    uid ??= _authService.uid;
    return _firestore
        .collection('users/$uid/items')
        .where('deleted', isEqualTo: isFetchingDeleted)
        .where('archived', isEqualTo: isFetchingArchived)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          return Item.fromSnapshot(doc);
        }).toList();
      }
      return <Item>[];
    });
  }

  @override
  Future<Response> unStarItems(List<Item> items) async {
    var hasError = false;

    try {
      final uid = _authService.uid;
      final batch = _firestore.batch();

      for (var item in items) {
        var docRef = _firestore.doc('users/$uid/items/${item.id}');
        batch.update(docRef, {'starred': false});
      }

      await batch.commit();

      logger.i('ItemService - softDeleteNewItems is successful');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ItemService - softDeleteNewItems failed\n$error\n$stackTrace');
      SentryUtil.error(
          'ItemService.softDeleteNewItems() error: List<Item> $items',
          'ItemService class',
          error,
          stackTrace);
    }

    return Response(hasError: hasError);
  }

  @override
  Future<Response<String>> createItem(Item item) async {
    var hasError = false;
    String? itemId;

    // final itemPrecise = toPreciseDecimal(item);

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/items').doc();

      // var requestBody = itemPrecise.toJson();
      var requestBody = item.toJson();

      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['starred'] = true;
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);

      itemId = docRef.id;
      logger.i('ItemService - createItem is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ItemService - createItem failed\n$error\n$stackTrace');
      SentryUtil.error('ItemService.createItem() error: Item $item',
          'ItemService class', error, stackTrace);
    }

    return Response(data: itemId, hasError: hasError);
  }

  @override
  Future<Response<String>> updateItem(
    Item item, [
    String? currentCountId,
  ]) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/items/${item.id}');

      var requestBody = item.toJson();

      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      if (currentCountId == null) {
        await docRef.update(requestBody);
        return Response(data: item.id, hasError: hasError);
      }

      final countRef = _firestore.doc('users/$uid/counts/$currentCountId');

      await _firestore.runTransaction((transaction) async {
        final countSnapshot = await transaction.get(countRef);
        if (countSnapshot.get('state') == 'started') {
          await _firestore
              .collection('users/$uid/countItems')
              .where('itemId', isEqualTo: item.id)
              .where('countId', isEqualTo: countRef.id)
              .get()
              .then((querySnapshot) {
            for (var doc in querySnapshot.docs) {
              transaction.update(doc.reference, {'cost': item.cost});
            }
          });
        }

        transaction.update(docRef, requestBody);
      });

      logger.i('ItemService - updateItem is successful ${docRef.id}');

      data = item.id;
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ItemService - updateItem failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemService.updateItem() error: Item $item, currentCountId $currentCountId',
        'ItemService class',
        error,
        stackTrace,
      );
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String>> updateItemDeletedStatus(
    Item item, {
    bool deleted = true,
  }) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/items/${item.id}');

      var requestBody = item.toJson();
      requestBody['deleted'] = deleted;
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);

      logger.i(
          'ItemService - updateItemDeletedStatus is successful ${docRef.id}');

      data = item.id;
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'ItemService - updateItemDeletedStatus failed\n$error\n$stackTrace');
      SentryUtil.error(
          'ItemService.updateItemDeletedStatus() error: Item $item',
          'ItemService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String>> setArchived(String itemId, bool value) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/items/$itemId');

      var requestBody = {
        'updatedAt': FieldValue.serverTimestamp(),
        'archived': value,
      };

      await docRef.update(requestBody);

      logger.i('ItemService - setArchived is successful ${docRef.id}');

      data = itemId;
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('ItemService - setArchived failed\n$error\n$stackTrace');
      SentryUtil.error(
        'ItemService.setArchived() error: Item $itemId',
        'ItemService class',
        error,
        stackTrace,
      );
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Stream<Item> getSingleItemById(String itemId,
      {bool isFetchingDeleted = false}) {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/items')
        .where('id', isEqualTo: itemId)
        .where('deleted', isEqualTo: isFetchingDeleted)
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) {
              return Item.fromJson(doc.data());
            })
            .toList()
            .first);
  }
}

class MockItemService implements ItemService {
  @override
  Future<Response<String?>> createItem(Item item) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<Item>> getItemsStream({
    String? uid,
    bool isFetchingDeleted = false,
    bool isFetchingArchived = false,
  }) {
    return Stream.value([]);
  }

  @override
  Future<Response> unStarItems(List<Item> items) {
    return Future.value(Response());
  }

  @override
  Future<Response<String?>> updateItem(Item item, [String? currentCountId]) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> updateItemDeletedStatus(Item item,
      {bool deleted = true}) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<Item> getSingleItemById(String itemId,
      {bool isFetchingDeleted = false}) {
    return Stream.value(Item());
  }

  @override
  Future<Response<String>> setArchived(String itemId, bool value) {
    return Future.value(Response(data: '1'));
  }
}
