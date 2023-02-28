// Flutter Packages
import 'dart:async';
import 'package:collection/collection.dart';
import 'package:flutter/foundation.dart';

// 3rd-Party Packages
import 'package:get_it/get_it.dart';

// Models
import 'package:stocklio_flutter/models/supplier.dart';

// Services
import 'package:stocklio_flutter/services/supplier_service.dart';

class SupplierProvider with ChangeNotifier {
  late SupplierService _supplierService;

  SupplierProvider({SupplierService? supplierService}) {
    _supplierService = supplierService ?? GetIt.instance<SupplierService>();
  }

  // States
  List<Supplier> _suppliers = [];
  StreamSubscription<List<Supplier>>? _suppliersStreamSub;
  bool _isLoading = true;
  bool _isInit = false;

  // Getters
  bool get isLoading => _isLoading;

  List<Supplier> get suppliers {
    _suppliersStreamSub ?? _listenToSuppliersStream();
    return [..._suppliers];
  }

  Future<void>? cancelStreamSubscriptions() {
    return _suppliersStreamSub?.cancel();
  }

  void _listenToSuppliersStream() {
    _suppliersStreamSub = _supplierService
        .getSuppliersStream()
        .listen((List<Supplier> suppliers) {
      _suppliers = suppliers;

      if (!_isInit) {
        _isInit = true;
        _isLoading = false;
      }

      notifyListeners();
    });
  }

  Supplier? findById(String id) {
    return suppliers.firstWhereOrNull((e) => e.id == id);
  }

  @override
  void dispose() {
    cancelStreamSubscriptions();
    super.dispose();
  }
}
