import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/count_area.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/count_area_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late CountAreaService countAreaService;

  setUp(() async {
    // A FakeFirebaseFirestore instance
    firestore = FakeFirebaseFirestore();

    // A MockFirebaseAuth instance
    firebaseAuth = MockFirebaseAuth();

    // Mocks of admin service and organization service
    final AdminService adminService = MockAdminService();
    final OrganizationService organizationService = MockOrganizationService();

    // An AuthService instance with a fake Firestore instance
    authService = AuthServiceImpl(
      firebaseAuth: firebaseAuth,
      adminService: adminService,
      organizationService: organizationService,
    );

    // An ItemService instance with a fake Firestore instance and AuthService instance
    countAreaService = CountAreaServiceImpl(
      firestore: firestore,
      authService: authService,
    );
  });

  test('Create count area service works', () async {
    final countArea = CountArea(name: 'new name');

    final response = await countAreaService.createCountArea(countArea);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Update count area service works', () async {
    final countArea =
        await countAreaService.createCountArea(CountArea(name: 'new name'));
    final newCountArea = CountArea(name: 'update name');

    final response = await countAreaService
        .updateCountArea(newCountArea.copyWith(id: countArea.data));

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Soft delete count area service works', () async {
    final countArea =
        await countAreaService.createCountArea(CountArea(name: 'new name'));
    final response =
        await countAreaService.softDeleteCountArea(countArea.data!);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
