// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';

// Models
import '../models/app_config.dart';

abstract class AppConfigService {
  Stream<AppConfig> getAppConfigStream();
}

class AppConfigServiceImpl implements AppConfigService {
  late FirebaseFirestore _firestore;

  AppConfigServiceImpl({FirebaseFirestore? firestore}) {
    _firestore = firestore ?? FirebaseFirestore.instance;
  }

  @override
  Stream<AppConfig> getAppConfigStream() {
    return _firestore
        .doc('appConfig/--config')
        .snapshots()
        .map((snapshot) => AppConfig.fromSnapshot(snapshot));
  }
}
