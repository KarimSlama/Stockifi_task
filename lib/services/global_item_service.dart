// Dart Packages
import 'dart:convert';

// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/global_item.dart';

abstract class GlobalItemService {
  Stream<List<GlobalItem>> getGlobalItemsStream();
}

class GlobalItemServiceImpl implements GlobalItemService {
  late FirebaseFirestore _firestore;

  GlobalItemServiceImpl({FirebaseFirestore? firestore}) {
    _firestore = firestore ?? FirebaseFirestore.instance;
  }

  @override
  Stream<List<GlobalItem>> getGlobalItemsStream() {
    Stream<List<GlobalItem>> globalItemsStream = Stream.value([]);
    List<GlobalItem> globalItemList = [];
    try {
      globalItemsStream =
          _firestore.collection('globalItemsData').snapshots().map((snapshot) {
        final maps = [];
        for (var doc in snapshot.docs) {
          // Ignore doc with id '--data' as it's outdated;
          // it exists because we use it @ functions & pwa
          if (doc.id == '--data') continue;

          final data = doc.data()['data'];
          maps.addAll(jsonDecode(data));
        }
        globalItemList = maps.map((json) => GlobalItem.fromJson(json)).toList();
        return globalItemList;
      });
      logger.i('GlobalItemService - getGlobalItemsStream is successful');
    } catch (error, stackTrace) {
      logger.e(
          'GlobalItemService - getGlobalItemsStream failed\n$error\n$stackTrace');
      SentryUtil.error('GlobalItemService.getGlobalItemsStream() error!',
          'GlobalItemService class', error, stackTrace);
    }
    return globalItemsStream;
  }
}

class MockGlobalItemService implements GlobalItemService {
  @override
  Stream<List<GlobalItem>> getGlobalItemsStream() {
    return Stream.value([]);
  }
}
