import 'dart:async';

import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:stocklio_flutter/utils/enums.dart';

class ConnectivityService {
  final _connectionStatusController = StreamController<ConnectivityStatus>();

  Stream<ConnectivityStatus> get stream => _connectionStatusController.stream;

  ConnectivityService() {
    Connectivity().onConnectivityChanged.listen((ConnectivityResult result) {
      _connectionStatusController.add(_getStatusFromResult(result));
    });
  }

  ConnectivityStatus _getStatusFromResult(ConnectivityResult result) {
    if (result == ConnectivityResult.none) {
      return ConnectivityStatus.offline;
    } else {
      return ConnectivityStatus.online;
    }
  }
}
