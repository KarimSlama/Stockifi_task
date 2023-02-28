import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:stocklio_flutter/models/profile.dart';

abstract class AdminService {
  Future<List<Profile>> getAllProfiles();
  String? selectedProfileId;
  bool isSelectedProfileAnOrganization = false;
}

class AdminServiceImpl implements AdminService {
  late final FirebaseFirestore _firestore;
  late final FirebaseAuth _firebaseAuth;

  AdminServiceImpl({
    FirebaseFirestore? firestore,
    FirebaseAuth? firebaseAuth,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance;

  @override
  String? selectedProfileId;

  @override
  bool isSelectedProfileAnOrganization = false;

  @override
  Future<List<Profile>> getAllProfiles() {
    return _firestore.collection('users').get().then((snapshot) {
      List<Profile> profiles = [];

      for (var doc in snapshot.docs) {
        if (doc.id == _firebaseAuth.currentUser?.uid) continue;
        profiles.add(Profile.fromSnapshot(doc));
      }

      return profiles;
    });
  }
}

class MockAdminService implements AdminService {
  @override
  bool isSelectedProfileAnOrganization = false;

  @override
  String? selectedProfileId;

  @override
  Future<List<Profile>> getAllProfiles() {
    return Future.value([]);
  }
}
