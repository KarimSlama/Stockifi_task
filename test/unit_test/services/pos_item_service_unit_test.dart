import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/pos_item.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';
import 'package:stocklio_flutter/services/pos_item_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late PosItemService posItemService;

  setUp(() async {
    firestore = FakeFirebaseFirestore();
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();
    await firebaseAuth.signInAnonymously();

    // Mocks of admin service and organization service
    final adminService = MockAdminService();
    final organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );
    posItemService = PosItemServiceImpl(
      authService: authService,
      firestore: firestore,
    );
  });

  test('POS Item should be updated from POS item service', () async {
    final posItem = PosItem.fromJson({
      'id': '0N2LCrM3VfkeSf96az9I',
      'items': {
        'dlZl51vMEwWLA8MYcHL3': 0.625,
        '6IIQFmMwwMpJ3OTnFMeW': 0.8,
        '0BgHMOLIpRfuA410DJM7': 0.625
      },
      'posData': {
        'name': 'Paloma',
        'shortName': 'Paloma',
        'price': 160,
        'sku': 160,
        'articleGroup': {'name': 'Classic Cocktails'},
        'active': true
      },
      'userId': 'guwNUbRIprYvxQaaRmslyv9sOGu2',
      'cost': 0,
      'costPerItem': null,
      'locked': false
    });

    final docRef = firestore
        .doc('users/${firebaseAuth.currentUser?.uid}/posItems/${posItem.id}');
    await docRef.set(posItem.toJson());

    final response = await posItemService.updatePOSItem(
      posItem.copyWith(
        items: {
          'dlZl51vMEwWLA8MYcHL3': 0.7,
          '6IIQFmMwwMpJ3OTnFMeW': 0.7,
          '0BgHMOLIpRfuA410DJM7': 0.7
        },
      ),
    );

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
