// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/pos_item.dart';

// Services
import '../models/response.dart';
import '../utils/logger_util.dart';
import 'auth_service.dart';

abstract class PosItemService {
  Stream<List<PosItem>> getPosItemsStream({
    bool isFetchingArchived = false,
  });
  Future<Response<String>> updatePOSItem(PosItem posItem, {String? taskId});
  Future<Response<String?>> setArchived(String posItemId, bool value);
}

class PosItemServiceImpl implements PosItemService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  PosItemServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<PosItem>> getPosItemsStream({
    bool isFetchingArchived = false,
  }) {
    Stream<List<PosItem>> posItemsStream = Stream.value([]);
    List<PosItem> posItemList = [];
    final uid = _authService.uid;
    try {
      posItemsStream = _firestore
          .collection('users/$uid/posItems')
          .where('archived', isEqualTo: isFetchingArchived)
          .where('items', isNull: false)
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          posItemList = snapshot.docs.map((doc) {
            return PosItem.fromSnapshot(doc);
          }).toList();
        }
        return posItemList;
      });
      logger.i('PosItemService - getPosItemsStream is successful');
    } catch (error, stackTrace) {
      logger
          .e('PosItemService - getPosItemsStream failed\n$error\n$stackTrace');

      SentryUtil.error('PosItemService.getPosItemsStream() error!',
          'PosItemService class', error, stackTrace);
    }
    return posItemsStream;
  }

  @override
  Future<Response<String>> updatePOSItem(
    PosItem posItem, {
    String? taskId,
  }) async {
    String? data;
    var hasError = false;

    try {
      final batch = _firestore.batch();
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/posItems/${posItem.id}');

      var requestBody = posItem.toJson();

      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      batch.update(docRef, requestBody);

      if (taskId != null) {
        final taskRef = _firestore.doc('users/$uid/tasks/$taskId');
        batch.update(taskRef, {
          'deleted': true,
          'updatedAt': FieldValue.serverTimestamp(),
        });
      }

      await batch.commit();

      data = docRef.id;
      logger.i('PosItemService - updatePOSItem is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('PosItemService - updatePOSItem failed\n$error\n$stackTrace');

      SentryUtil.error('PosItemService.updatePOSItem() error: PosItem $posItem',
          'PosItemService class', error, stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> setArchived(String posItemId, bool value) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/posItems/$posItemId');

      var requestBody = {
        'updatedAt': FieldValue.serverTimestamp(),
        'archived': value,
      };

      await docRef.update(requestBody);

      data = docRef.id;

      logger.i('PosItemService - setArchived is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('PosItemService - setArchived failed\n$error\n$stackTrace');

      SentryUtil.error(
        'PosItemService.setArchived() error: PosItem ID $posItemId',
        'PosItemService class',
        error,
        stackTrace,
      );
    }

    return Response(data: data, hasError: hasError);
  }
}

class MockPOSItemService implements PosItemService {
  @override
  Stream<List<PosItem>> getPosItemsStream({
    bool isFetchingArchived = false,
  }) {
    return Stream.value([]);
  }

  @override
  Future<Response<String>> updatePOSItem(PosItem posItem, {String? taskId}) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> setArchived(String posItemId, bool value) {
    return Future.value(Response(data: '1'));
  }
}
