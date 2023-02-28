import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/app_config.dart';
import 'package:stocklio_flutter/services/app_config_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late AppConfigService appconfigService;
  late AppConfig data;
  late DocumentReference docRef;

  setUp(() async {
    firestore = FakeFirebaseFirestore();

    appconfigService = AppConfigServiceImpl(
      firestore: firestore,
    );
    data = AppConfig(maintenance: false, version: 24);
    docRef = firestore.doc('appConfig/--config');
    await docRef.set(data.toJson());
  });

  test('AppConfig maintenance should be false', () async {
    final response = appconfigService.getAppConfigStream();
    var appConfigData = AppConfig();
    await response.first.then((value) => {appConfigData = value});
    expect(appConfigData.maintenance, false);
  });

  test('AppConfig version should be "24"', () async {
    final response = appconfigService.getAppConfigStream();
    var appConfigData = AppConfig();
    await response.first.then((value) => {appConfigData = value});
    expect(appConfigData.version, 24);
  });
}
