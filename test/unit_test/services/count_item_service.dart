import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/count_item.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/count_item_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late CountItemService countItemService;

  setUp(() async {
    // A FakeFirebaseFirestore instance
    firestore = FakeFirebaseFirestore();
    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();

    // Mocks of admin service and organization service
    final adminService = MockAdminService();
    final organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );
    // An ItemService instance with a fake Firestore instance and AuthService instance
    countItemService = CountItemServiceImpl(
      firestore: firestore,
      authService: authService,
    );
  });

  test('Create count item service works', () async {
    final countItem = CountItem(
      countId: '123',
      calc: '123',
      itemId: '123',
      areaId: '123',
    );

    final response = await countItemService.createCountItem(countItem);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Update count area service works', () async {
    final countItem = await countItemService.createCountItem(
      CountItem(
        countId: '123',
        calc: '123',
        itemId: '123',
        areaId: '123',
      ),
    );

    final newCountItem = CountItem(
      countId: '123',
      calc: '456',
      itemId: '123',
      areaId: '456',
    );

    final response = await countItemService.updateCountItem(
      newCountItem.copyWith(id: countItem.data),
    );

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Delete count item service works', () async {
    final countItem = await countItemService.createCountItem(
      CountItem(
        countId: '123',
        calc: '123',
        itemId: '123',
        areaId: '123',
      ),
    );

    final response = await countItemService.deleteCountItem(countItem.data!);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
