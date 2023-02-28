// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/services/auth_service.dart';

// Models
import '../models/wastage.dart';

// Services
import '../models/response.dart';

// Utils
import '../utils/logger_util.dart';

abstract class WastageService {
  Stream<List<Wastage>> getWastagesStream();
  Stream<List<Wastage>> getCurrentStartedWastageStream();
  Future<Response<String?>> createWastage(Wastage wastage);
  Future<Response<String?>> updateWastage(Wastage wastage);
  Future<Response<String?>> softDeleteWastage(String wastageId);
  Future<Response<String?>> lockWastage(Wastage wastage);
  Future<Response<String?>> unlockWastage(Wastage wastage);
}

class WastageServiceImpl implements WastageService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  WastageServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<Wastage>> getWastagesStream() {
    final uid = _authService.uid;

    return _firestore
        .collection('users/$uid/wastages')
        .where('deleted', isEqualTo: false)
        .orderBy('updatedAt', descending: true)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        logger.i(
            'SERVICE - getWastagesStream - snapshot.docs - ${snapshot.size}');
        final wastages =
            snapshot.docs.map((doc) => Wastage.fromSnapshot(doc)).toList();

        return wastages;
      }
      logger.i('SERVICE - getWastagesStream - snapshot.docs is empty');
      return <Wastage>[];
    }).handleError((e, s) => logger.e('SERVICE - getWastagesStream\n$e\n$s'));
  }

  @override
  Stream<List<Wastage>> getCurrentStartedWastageStream() {
    final uid = _authService.uid;

    return _firestore
        .collection('users/$uid/wastages')
        .where('deleted', isEqualTo: false)
        .where('state', isEqualTo: 'started')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        logger.i(
            'SERVICE - getWastagesStream - snapshot.docs - ${snapshot.size}');
        final wastages =
            snapshot.docs.map((doc) => Wastage.fromSnapshot(doc)).toList();

        return wastages;
      }
      logger.i('SERVICE - getWastagesStream - snapshot.docs is empty');
      return <Wastage>[];
    }).handleError((e, s) => logger.e('SERVICE - getWastagesStream\n$e\n$s'));
  }

  @override
  Future<Response<String?>> createWastage(Wastage wastage) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/wastages').doc();

      var requestBody = wastage.toJson();
      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);

      data = docRef.id;

      logger.i('SERVICE - createWastage is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - createWastage failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> updateWastage(Wastage wastage) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/wastages/${wastage.id}');

      var requestBody = wastage.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);
      data = docRef.id;
      logger.i('SERVICE - updateWastage is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - updateWastage failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> lockWastage(Wastage wastage) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/wastages/${wastage.id}');

      var requestBody = wastage.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['state'] = "locked";

      await docRef.update(requestBody);
      data = docRef.id;
      logger.i('SERVICE - lockWastage is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - lockWastage failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> unlockWastage(Wastage wastage) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/wastages/${wastage.id}');

      var requestBody = wastage.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['state'] = "started";

      await docRef.update(requestBody);
      data = docRef.id;
      logger.i('SERVICE - lockWastage is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - lockWastage failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> softDeleteWastage(String wastageId) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/wastages/$wastageId');

      var requestBody = <String, dynamic>{};
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = true;

      await docRef.update(requestBody);
      data = docRef.id;
      logger.i('SERVICE - softDeleteWastage is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - softDeleteWastage failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }
}

class MockWastageService implements WastageService {
  @override
  Future<Response<String?>> createWastage(Wastage wastage) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<Wastage>> getWastagesStream() {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> softDeleteWastage(String wastageId) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> updateWastage(Wastage wastage) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> lockWastage(Wastage wastage) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> unlockWastage(Wastage wastage) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<Wastage>> getCurrentStartedWastageStream() {
    return Stream.value([]);
  }
}
