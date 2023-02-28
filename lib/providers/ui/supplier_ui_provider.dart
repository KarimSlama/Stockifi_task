// ignore_for_file: prefer_final_fields

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:stocklio_flutter/models/supplier.dart';

class SupplierUIProvider with ChangeNotifier {
  List<Supplier> _supplierList = [];

  List<Supplier> get supplierList => _supplierList;

  void addSupplierFilter(Supplier _) {
    _supplierList.add(_);
    notifyListeners();
  }

  void removeSupplierFilter(Supplier _) {
    _supplierList.remove(_);
    notifyListeners();
  }

  void clearSupplierFilters() {
    _supplierList.clear();
    notifyListeners();
  }
}
