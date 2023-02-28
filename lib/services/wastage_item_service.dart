// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';

// Models
import '../models/wastage_item.dart';

// Services
import '../models/response.dart';
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';

abstract class WastageItemService {
  Stream<List<WastageItem>> getWastageItemsStream(String wastageId);
  Future<Response<String?>> createWastageItem(WastageItem wastageItem);
  Future<Response<String?>> updateWastageItem(WastageItem wastageItem);
  Future<Response<String?>> deleteWastageItem(String id);
}

class WastageItemServiceImpl implements WastageItemService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  WastageItemServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<WastageItem>> getWastageItemsStream(String wastageId) {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/wastageItems')
        .where('wastageId', isEqualTo: wastageId)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) {
          // return toPreciseDecimal(WastageItem.fromSnapshot(doc));
          return WastageItem.fromSnapshot(doc);
        }).toList();
      }
      return <WastageItem>[];
    });
  }

  @override
  Future<Response<String?>> createWastageItem(WastageItem wastageItem) async {
    var hasError = false;
    String? newWastageItemId;

    // final wastageItemPrecise = toPreciseDecimal(wastageItem);

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/wastageItems').doc();

      // var requestBody = wastageItemPrecise.toJson();
      var requestBody = wastageItem.toJson();

      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);

      newWastageItemId = docRef.id;

      logger.i('SERVICE - createWastageItem is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - createWastageItem failed \n$e\n$s');
    }

    return Response(data: newWastageItemId, hasError: hasError);
  }

  @override
  Future<Response<String?>> updateWastageItem(WastageItem wastageItem) async {
    String? data;
    var hasError = false;

    // final wastageItemPrecise = toPreciseDecimal(wastageItem);

    try {
      final uid = _authService.uid;
      final docRef =
          _firestore.doc('users/$uid/wastageItems/${wastageItem.id}');

      // var requestBody = wastageItemPrecise.toJson();
      var requestBody = wastageItem.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);

      data = docRef.id;

      logger.i('SERVICE - updateWastageItem is successful ${wastageItem.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - updateWastageItem failed ${wastageItem.id}\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> deleteWastageItem(String id) async {
    String? data;
    var hasError = false;
    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/wastageItems/$id');

      await docRef.delete();

      data = docRef.id;

      logger.i('SERVICE - deleteWastageItem is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - deleteWastageItem failed $id\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  // WastageItem toPreciseDecimal(WastageItem wastageItem) {
  //   final wastageItemCost = wastageItem.cost;
  //   final wastageItemAvgQuantity = wastageItem.quantity;

  //   final wastageItemCostPrecise = wastageItemCost.toDouble().toPrecision(2);
  //   final iwastageItemAvgQuantityPrecise =
  //       wastageItemAvgQuantity.toPrecision(2);

  //   final wastageItemPrecise = wastageItem.copyWith(
  //     cost: wastageItemCostPrecise,
  //     quantity: iwastageItemAvgQuantityPrecise,
  //   );
  //   return wastageItemPrecise;
  // }
}

class MockWastageItemService implements WastageItemService {
  @override
  Future<Response<String?>> createWastageItem(WastageItem wastageItem) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> deleteWastageItem(String id) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<WastageItem>> getWastageItemsStream(String wastageId) {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> updateWastageItem(WastageItem wastageItem) {
    return Future.value(Response(data: '1'));
  }
}
