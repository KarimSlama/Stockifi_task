// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/report_item.dart';
import 'package:stocklio_flutter/services/auth_service.dart';

// Models
import '../models/count.dart';

// Services
import '../models/response.dart';

// Utils
import '../utils/logger_util.dart';

abstract class CountService {
  Stream<List<Count>> getCountsStream();
  Future<Response<String?>> createCount(Count count);
  Future<Response<String?>> updateCount(Count count);
  Future<Response<String?>> softDeleteCount(String countId);
  Future<Response<Map<String, List<ReportItem>>>> getCountReport(
      String countId);
  Future<Response<String?>> lockCount(Count count);
}

class CountServiceImpl implements CountService {
  late final FirebaseFirestore _firestore;
  late final FirebaseFunctions _functions;
  late final AuthService _authService;

  CountServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseFunctions? functions,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _functions = functions ?? FirebaseFunctions.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<Count>> getCountsStream() {
    final uid = _authService.uid;

    return _firestore
        .collection('users/$uid/counts')
        .orderBy('sortKey')
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        logger
            .i('SERVICE - getCountsStream - snapshot.docs - ${snapshot.size}');
        final counts =
            snapshot.docs.map((doc) => Count.fromSnapshot(doc)).toList();

        return counts;
      }
      logger.i('SERVICE - getCountsStream - snapshot.docs is empty');
      return <Count>[];
    }).handleError((e, s) => logger.e('SERVICE - getCountsStream\n$e\n$s'));
  }

  @override
  Future<Response<String?>> createCount(Count count) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/counts').doc();
      final profileRef = _firestore.doc('users/$uid');

      await _firestore.runTransaction((transaction) async {
        final profileSnapshot = await transaction.get(profileRef);
        final hasAnActiveCount = profileSnapshot.data()?['hasAnActiveCount'];

        if (hasAnActiveCount == null || hasAnActiveCount == false) {
          var requestBody = count.toJson();
          requestBody['createdAt'] = FieldValue.serverTimestamp();
          requestBody['updatedAt'] = FieldValue.serverTimestamp();
          requestBody['deleted'] = false;
          requestBody['id'] = docRef.id;

          transaction.set(docRef, requestBody);
          transaction.update(
            profileRef,
            {
              'hasAnActiveCount': true,
              'updatedAt': FieldValue.serverTimestamp(),
            },
          );
        }
      });

      data = docRef.id;

      logger.i('SERVICE - createCount is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - createCount failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> lockCount(Count count) async {
    String? data;
    var hasError = false;

    try {
      final batch = _firestore.batch();

      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/counts/${count.id!}');
      final profileRef = _firestore.doc('users/$uid');

      var requestBody = count.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;
      requestBody['state'] = 'complete';

      data = docRef.id;

      batch.update(docRef, requestBody);
      batch.update(
        profileRef,
        {
          'hasAnActiveCount': false,
          'updatedAt': FieldValue.serverTimestamp(),
        },
      );

      await batch.commit();

      logger.i('SERVICE - lockCount is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - lockCount failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> updateCount(Count count) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/counts/${count.id}');

      var requestBody = count.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      if (count.report == 'delete') {
        requestBody['report'] = FieldValue.delete();
      }

      await docRef.update(requestBody);
      data = docRef.id;
      logger.i('SERVICE - updateCount is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - updateCount failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> softDeleteCount(String countId) async {
    String? data;
    var hasError = false;

    try {
      final batch = _firestore.batch();

      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/counts/$countId');
      final profileRef = _firestore.doc('users/$uid');

      var requestBody = <String, dynamic>{};
      requestBody['deleted'] = true;

      data = docRef.id;

      batch.update(docRef, requestBody);
      batch.update(
        profileRef,
        {'hasAnActiveCount': false},
      );

      await batch.commit();
      logger.i('SERVICE - softDeleteCount is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - softDeleteCount failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<Map<String, List<ReportItem>>>> getCountReport(
    String countId,
  ) async {
    Map<String, List<ReportItem>>? data;
    var hasError = false;

    try {
      final callable = _functions.httpsCallable('getCountReport');

      final response = await callable.call(
        {
          'userId': _authService.uid,
          'countId': countId,
        },
      );

      final report = decodeReports(response.data['report']);
      final areaReport = decodeReports(response.data['areaReport']);

      data = {'report': report, 'areaReport': areaReport};
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - getCountReport failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }
}

class MockCountService implements CountService {
  @override
  Future<Response<String?>> createCount(Count count) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<Count>> getCountsStream() {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> softDeleteCount(String countId) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> updateCount(Count count) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<Map<String, List<ReportItem>>>> getCountReport(
      String countId) {
    return Future.value(Response(data: {'report': [], 'areaReport': []}));
  }

  @override
  Future<Response<String?>> lockCount(Count count) {
    return Future.value(Response(data: '1'));
  }
}
