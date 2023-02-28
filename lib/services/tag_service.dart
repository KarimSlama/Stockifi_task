import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/models/tag.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';

abstract class TagService {
  Stream<List<Tag>> getUserTagsStream();
  Future<Response<String?>> createTag(Tag tag);
}

class TagServiceImpl implements TagService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  TagServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<Tag>> getUserTagsStream() {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/tags')
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Tag.fromSnapshot(doc)).toList();
      }
      return <Tag>[];
    });
  }

  @override
  Future<Response<String?>> createTag(Tag tag) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/tags').doc();

      var requestBody = tag.toJson();
      requestBody['createdAt'] = FieldValue.serverTimestamp();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = false;
      requestBody['id'] = docRef.id;

      await docRef.set(requestBody);

      data = docRef.id;

      logger.i('SERVICE - createTag is successful ${docRef.id}');
    } catch (e, s) {
      hasError = true;
      logger.e('SERVICE - createTag failed\n$e\n$s');
    }

    return Response(data: data, hasError: hasError);
  }
}
