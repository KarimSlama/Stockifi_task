import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/models/shortcut.dart';
import 'package:stocklio_flutter/services/auth_service.dart';

abstract class ShortcutService {
  Stream<List<Shortcut>> getUserShortcutsStream();
  Stream<List<Shortcut>> getGlobalShortcutsStream();
}

class ShortcutServiceImpl implements ShortcutService {
  late final FirebaseFirestore _firestore;
  late final AuthService _authService;

  ShortcutServiceImpl({
    FirebaseFirestore? firestore,
    AuthService? authService,
  }) {
    _firestore = firestore ?? FirebaseFirestore.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Stream<List<Shortcut>> getUserShortcutsStream() {
    final uid = _authService.uid;
    return _firestore
        .collection('users/$uid/shortcuts')
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Shortcut.fromSnapshot(doc)).toList();
      }
      return <Shortcut>[];
    });
  }

  @override
  Stream<List<Shortcut>> getGlobalShortcutsStream() {
    return _firestore
        .collection('globalShortcuts')
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Shortcut.fromSnapshot(doc)).toList();
      }
      return <Shortcut>[];
    });
  }
}
