// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/count_area.dart';

// Services
import '../models/response.dart';
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';

abstract class CountAreaService {
  Stream<List<CountArea>> getCountAreasStream();
  Future<Response<String?>> createCountArea(CountArea countArea);
  Future<Response<String?>> updateCountArea(CountArea countArea);
  Future<Response<String?>> softDeleteCountArea(String countAreaId);
}

class CountAreaServiceImpl implements CountAreaService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  CountAreaServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<CountArea>> getCountAreasStream() {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/countAreas')
        .where('deleted', isEqualTo: false)
        .orderBy('name')
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => CountArea.fromSnapshot(doc)).toList();
      }
      return <CountArea>[];
    });
  }

  @override
  Future<Response<String?>> createCountArea(CountArea countArea) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/countAreas').doc();

      var requestBody = countArea.toJson();
      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);

      data = docRef.id;

      logger.i('CountAreaService - createCountArea is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger
          .e('CountAreaService - createCountArea failed\n$error\n$stackTrace');
      SentryUtil.error(
          'CountAreaService.createCountArea() error: CountArea $countArea',
          'CountAreaService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> updateCountArea(CountArea countArea) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/countAreas/${countArea.id}');

      var requestBody = countArea.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      await docRef.update(requestBody);

      data = docRef.id;

      logger.i(
          'CountAreaService - updateCountArea is successful ${countArea.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'CountAreaService - updateCountArea failed ${countArea.id}\n$error\n$stackTrace');
      SentryUtil.error(
          'CountAreaService.updateCountArea() error: CountArea $countArea',
          'CountAreaService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> softDeleteCountArea(String countAreaId) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/countAreas/$countAreaId');

      var requestBody = {
        'deleted': true,
        'updatedAt': FieldValue.serverTimestamp(),
      };

      await docRef.update(requestBody);

      data = docRef.id;

      logger.i('CountAreaService - deleteCountArea is successful $countAreaId');
    } catch (error, stackTrace) {
      hasError = true;
      logger.i(
          'CountAreaService - deleteCountArea failed $countAreaId\n$error\n$stackTrace');
      SentryUtil.error(
          'CountAreaService.softDeleteCountArea() error: CountAreaId $countAreaId',
          'CountAreaService class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }
}

class MockCountAreaService implements CountAreaService {
  @override
  Future<Response<String?>> createCountArea(CountArea countArea) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<CountArea>> getCountAreasStream() {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> softDeleteCountArea(String countAreaId) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> updateCountArea(CountArea countArea) {
    return Future.value(Response(data: '1'));
  }
}
