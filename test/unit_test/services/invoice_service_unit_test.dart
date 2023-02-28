import 'dart:io';
import 'dart:typed_data';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:fake_cloud_firestore/fake_cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_auth_mocks/firebase_auth_mocks.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:stocklio_flutter/models/cloud_storage_result.dart';
import 'package:stocklio_flutter/models/invoice.dart';
import 'package:stocklio_flutter/models/response.dart';
import 'package:stocklio_flutter/services/admin_service.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/services/file_uploader_service.dart';
import 'package:stocklio_flutter/services/invoice_service.dart';
import 'package:stocklio_flutter/services/organization_service.dart';

class MockFailingFileUploaderService implements FileUploaderService {
  @override
  Future<Response<CloudStorageResult>> uploadImage(
    String imageFileName,
    Uint8List imageToUpload,
  ) async {
    return Response<CloudStorageResult>(hasError: true, data: null);
  }

  @override
  Future<Response<CloudStorageResult>> uploadInvoiceImage(
    String invoiceId,
    Uint8List imageToUpload,
  ) async {
    return Response<CloudStorageResult>(hasError: true, data: null);
  }
}

void main() {
  late FirebaseFirestore firestore;
  late FirebaseAuth firebaseAuth;
  late AuthService authService;
  late InvoiceService invoiceService;
  late Response<String> createdInvoice;
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
    // An InvoiceService instance with a fake Firestore instance and AuthService instance
    invoiceService = InvoiceServiceImpl(
      firestore: firestore,
      authService: authService,
      fileUploaderService: MockFileUploaderService(),
    );

    /* ----------------------- Existing invoice in the DB ----------------------- */

    // GIVEN
    final invoice = Invoice();

    // A test image to be uploaded
    final bytes = await File('test_resources/logo.png').readAsBytes();
    expect(bytes, isNotNull);

    createdInvoice =
        await invoiceService.createInvoice(invoice, newImagesToUpload: [bytes]);

    /* -------------------------------------------------------------------------- */
  });

  test('Invoice should be created from invoice service', () async {
    // GIVEN
    // An Invoice instance with the following parameters
    final invoice = Invoice();

    // A test image to be uploaded
    final bytes = await File('test_resources/logo.png').readAsBytes();
    expect(bytes, isNotNull);

    // WHEN
    // createInvoice() is called
    final response =
        await invoiceService.createInvoice(invoice, newImagesToUpload: [bytes]);

    // THEN
    // invoice data should not be null
    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Invoice comment should be added from invoice service', () async {
    expect(createdInvoice.data!, isNotNull);

    final response = await invoiceService.addInvoiceComment(
        createdInvoice.data!, 'new comment');

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
  test('Invoice upload should fail if file upload failed', () async {
    final invoiceService = InvoiceServiceImpl(
      firestore: firestore,
      authService: authService,
      fileUploaderService: MockFailingFileUploaderService(),
    );

    // GIVEN
    // An Invoice instance with the following parameters
    final invoice = Invoice();

    // A test image to be uploaded
    final bytes = await File('test_resources/logo.png').readAsBytes();
    expect(bytes, isNotNull);

    // WHEN
    // createInvoice() is called
    final response =
        await invoiceService.createInvoice(invoice, newImagesToUpload: [bytes]);

    // THEN
    // invoice data should not be null
    expect(response.data, isNull);
    expect(response.hasError, true);
  });

  test('Invoice should be updated from invoice service', () async {
    // GIVEN
    // A test image to be uploaded
    final bytes = await File('test_resources/logo.png').readAsBytes();
    expect(bytes, isNotNull);

    // And a new Invoice instance with updated fields
    final newInvoice = Invoice(
      id: createdInvoice.data,
      comments: ['test new comment'],
    );

    // WHEN
    // updateInvoice() is called
    final response = await invoiceService
        .updateInvoice(newInvoice, newImagesToUpload: [bytes]);

    // THEN
    // response should not be null
    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Invoice image should be deleted', () async {
    final response = await invoiceService.deleteInvoiceImage(
        createdInvoice.data!, 'testUrl');

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });

  test('Invoice should be soft deleted', () async {
    final response =
        await invoiceService.softDeleteInvoice(createdInvoice.data!);

    expect(response.data, isNotNull);
    expect(response.hasError, false);
  });
}
