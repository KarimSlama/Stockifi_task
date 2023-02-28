import 'package:firebase_database/firebase_database.dart';
import 'package:stocklio_flutter/utils/package_util.dart';

// TODO: see if this can be improved
class Presence {
  final DatabaseReference databaseReference =
      FirebaseDatabase.instance.ref('users');

  final presenceStatusTrue = {
    'presence': true,
    'last_seen': DateTime.now().millisecondsSinceEpoch,
    'app_version': PackageUtil.packageInfo.version,
  };

  final presenceStatusFalse = {
    'presence': false,
    'last_seen': DateTime.now().millisecondsSinceEpoch,
    'app_version': PackageUtil.packageInfo.version,
  };

  Future<void> setUserPresence(uid) async {
    await databaseReference.child(uid).update(presenceStatusTrue);
    /* .whenComplete(() => print('Presence is set.')) */
    /* .catchError((e) => print(e)); */

    return databaseReference
        .child(uid)
        .onDisconnect()
        .update(presenceStatusFalse);
  }

  Future<void> updateUserPresence(uid) async {
    return databaseReference.child(uid).update(presenceStatusFalse);
    /* .whenComplete(() => print('Presence is updated.')) */
    /* .catchError((e) => print(e)); */
  }
}
