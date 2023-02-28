import 'dart:io';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:firebase_storage_mocks/firebase_storage_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/file_uploader_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

void main() {
  late FirebaseStorage storage;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  // ignore: unused_local_variable
  late FileUploaderService fileUploaderService;

  setUp(() async {
    // A FakeFirebaseFirestore instance
    storage = MockFirebaseStorage();
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
    // An fileUploaderService instance with a fake Storage instance and AuthService instance
    fileUploaderService = FileUploaderServiceImpl(
      authService: authService,
      storage: storage,
    );
  });

  test('Upload file service works', () async {
    final bytes = await File('test_resources/logo.png').readAsBytes();

    expect(bytes, isNotNull);

    final response = await fileUploaderService.uploadImage('test', bytes);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Update invoice image service works', () async {
    final response = await fileUploaderService.uploadInvoiceImage(
        'test', await File('test_resources/logo.png').readAsBytes());

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
