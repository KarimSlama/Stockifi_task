// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';

// Models
import 'package:stocklio_flutter/models/supplier.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

abstract class SupplierService {
  Stream<List<Supplier>> getSuppliersStream();
}

class SupplierServiceImpl implements SupplierService {
  late FirebaseFirestore _firestore;

  SupplierServiceImpl({FirebaseFirestore? firestore}) {
    _firestore = firestore ?? FirebaseFirestore.instance;
  }

  @override
  Stream<List<Supplier>> getSuppliersStream() {
    Stream<List<Supplier>> suppliersStream = Stream.value([]);
    List<Supplier> supplierList = [];
    try {
      suppliersStream = _firestore
          .collection('suppliers')
          .orderBy('name')
          .snapshots()
          .map((snapshot) {
        if (snapshot.docs.isNotEmpty) {
          supplierList =
              snapshot.docs.map((doc) => Supplier.fromSnapshot(doc)).toList();
          return supplierList;
        }
        return supplierList;
      });
      logger.i('SupplierService - getSuppliersStream is successful');
      return suppliersStream;
    } catch (error, stackTrace) {
      logger.e(
          'SupplierService - getSuppliersStream failed\n$error\n$stackTrace');

      SentryUtil.error('SupplierService.getSuppliersStream() error!',
          'SupplierService class', error, stackTrace);
    }
    return suppliersStream;
  }
}

class MockSupplierService implements SupplierService {
  @override
  Stream<List<Supplier>> getSuppliersStream() {
    return Stream.value([]);
  }
}
