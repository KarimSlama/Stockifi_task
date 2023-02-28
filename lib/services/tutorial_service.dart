import 'dart:developer';

import 'package:firebase_storage/firebase_storage.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/models/tutorial.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stocklio_flutter/models/tutorial_media.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';

abstract class TutorialService {
  Stream<List<Tutorial>> getTutorialsStream();
  Future<Response> getTutorialMedia(String path);
}

class TutorialServiceImpl implements TutorialService {
  late final FirebaseFirestore _firestore;
  late final FirebaseStorage _storage;

  TutorialServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseStorage? storage,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _storage = storage ?? FirebaseStorage.instance;
  }

  @override
  Stream<List<Tutorial>> getTutorialsStream() {
    return _firestore
        .collection('appTutorials')
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Tutorial.fromSnapshot(doc)).toList();
      }
      return <Tutorial>[];
    }).handleError((e, s) => logger.e('SERVICE - getTutorialsStream\n$e\n$s'));
  }

  @override
  Future<Response> getTutorialMedia(String path) async {
    late String url;
    FullMetadata? metadata;

    var hasError = false;
    if (path.contains('http')) {
      url = path;
    } else {
      try {
        final ref = _storage.ref(path.replaceAll('storage/', ''));
        url = await ref.getDownloadURL();
        metadata = await ref.getMetadata();
      } catch (e) {
        hasError = true;
        log('debug TutorialService getTutorialMediaUrl failed $e');
      }
    }

    return Response(
      data: TutorialMedia(url: url, metadata: metadata),
      hasError: hasError,
    );
  }
}
