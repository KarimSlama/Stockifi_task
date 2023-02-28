// Dart Packages
import 'dart:typed_data';

// 3rd-Party Packages
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:get_it/get_it.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

// Models
import '../models/invoice.dart';

// Services
import '../models/response.dart';
import 'auth_service.dart';

// Utils
import '../utils/logger_util.dart';
import 'file_uploader_service.dart';

abstract class InvoiceService {
  Stream<List<Invoice>> getInvoicesStream();
  Future<Response<String>> createInvoice(
    Invoice invoice, {
    List<Uint8List>? newImagesToUpload,
  });
  Future<Response<String>> updateInvoice(
    Invoice invoice, {
    List<Uint8List>? newImagesToUpload,
  });
  Future<Response<String?>> addInvoiceComment(
    String invoiceId,
    String comment,
  );
  Future<Response<String?>> deleteInvoiceImage(
    String invoiceId,
    String imageUrl,
  );
  Future<Response<String?>> softDeleteInvoice(
    String invoiceId, [
    String? imageUrl,
  ]);
}

class InvoiceServiceImpl implements InvoiceService {
  late final FirebaseFirestore _firestore;
  late final FileUploaderService _fileUploaderService;
  late final AuthService _authService;

  InvoiceServiceImpl({
    FirebaseFirestore? firestore,
    FileUploaderService? fileUploaderService,
    AuthService? authService,
  })  : _firestore = firestore ?? FirebaseFirestore.instance,
        _fileUploaderService =
            fileUploaderService ?? GetIt.instance<FileUploaderService>(),
        _authService = authService ?? GetIt.instance<AuthService>();

  @override
  Stream<List<Invoice>> getInvoicesStream() {
    final uid = _authService.uid;
    return _firestore
        .collection('users')
        .doc(uid)
        .collection('invoices')
        .orderBy('createdAt', descending: true)
        .where('deleted', isEqualTo: false)
        .snapshots()
        .map((snapshot) {
      if (snapshot.docs.isNotEmpty) {
        return snapshot.docs.map((doc) => Invoice.fromSnapshot(doc)).toList();
      }
      return <Invoice>[];
    });
  }

  @override
  Future<Response<String>> createInvoice(
    Invoice invoice, {
    List<Uint8List>? newImagesToUpload,
  }) async {
    var hasError = false;
    String? newInvoiceId;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.collection('users/$uid/invoices').doc();

      if (newImagesToUpload != null) {
        final files = <String>[];
        for (var image in newImagesToUpload) {
          final response = await _fileUploaderService.uploadInvoiceImage(
            docRef.id,
            image,
          );
          if (response.hasError || response.data == null) {
            return Response<String>(hasError: true);
          } else {
            files.add(response.data!.downloadUrl!);
          }
        }

        invoice = invoice.copyWith(userId: uid, state: 'unresolved');
        var requestBody = invoice.toJson();

        requestBody['path'] = 'users/$uid/invoices/${docRef.id}';
        requestBody['createdAt'] = FieldValue.serverTimestamp();
        requestBody['updatedAt'] = FieldValue.serverTimestamp();
        requestBody['deleted'] = false;
        requestBody['id'] = docRef.id;
        requestBody['files'] = FieldValue.arrayUnion(files);
        requestBody['url'] = files.first;
        requestBody['isCreatedByUser'] = true;

        await docRef.set(requestBody);

        newInvoiceId = docRef.id;
        logger.i('InvoiceService - createInvoice is successful ${docRef.id}');
      }
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('InvoiceService - createInvoice failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceService.createInvoice error: Invoice $invoice, List<Uint8List> $newImagesToUpload',
          'InvoiceService class',
          error,
          stackTrace);
    }
    return Response(data: newInvoiceId, hasError: hasError);
  }

  @override
  Future<Response<String>> updateInvoice(
    Invoice invoice, {
    List<Uint8List>? newImagesToUpload,
  }) async {
    var hasError = false;
    String? updatedInvoiceId;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/invoices/${invoice.id}');

      var requestBody = invoice.toJson();
      requestBody['updatedAt'] = FieldValue.serverTimestamp();

      if (newImagesToUpload != null && newImagesToUpload.isNotEmpty) {
        var files = [];
        for (var image in newImagesToUpload) {
          final response = await _fileUploaderService.uploadInvoiceImage(
            docRef.id,
            image,
          );
          files.add(response.data?.downloadUrl);
        }

        requestBody['files'] = FieldValue.arrayUnion(files);
        requestBody['url'] = files.first;
      }

      await docRef.update(requestBody);
      updatedInvoiceId = docRef.id;
      logger.i('InvoiceService - updateInvoice is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e('InvoiceService - updateInvoice failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceService.updateInvoice error: Invoice $invoice, List<Uint8List> $newImagesToUpload',
          'InvoiceService class',
          error,
          stackTrace);
    }

    return Response(data: updatedInvoiceId, hasError: hasError);
  }

  @override
  Future<Response<String?>> addInvoiceComment(
      String invoiceId, String comment) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/invoices/$invoiceId');

      var requestBody = <String, dynamic>{};
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['comments'] = FieldValue.arrayUnion([comment]);

      await docRef.update(requestBody);

      data = docRef.id;
      logger.i('InvoiceService - addInvoiceComment is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger
          .e('InvoiceService - addInvoiceComment failed\n$error\n$stackTrace');

      SentryUtil.error(
          'InvoiceProvider.addInvoiceComment error: Invoice ID $invoiceId, Comment $comment',
          'InvoiceProvider class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> deleteInvoiceImage(
      String invoiceId, String imageUrl) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/invoices/$invoiceId');

      var requestBody = <String, dynamic>{};
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['files'] = FieldValue.arrayRemove([imageUrl]);

      await docRef.update(requestBody);

      data = docRef.id;
      logger
          .i('InvoiceService - deleteInvoiceImage is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger
          .e('InvoiceService - deleteInvoiceImage failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceProvider.deleteInvoiceImage error: Invoice ID $invoiceId, imageUrl $imageUrl',
          'InvoiceProvider class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }

  @override
  Future<Response<String?>> softDeleteInvoice(
    String invoiceId, [
    String? imageUrl,
  ]) async {
    String? data;
    var hasError = false;

    try {
      final uid = _authService.uid;
      final docRef = _firestore.doc('users/$uid/invoices/$invoiceId');

      var requestBody = <String, dynamic>{};
      requestBody['updatedAt'] = FieldValue.serverTimestamp();
      requestBody['deleted'] = true;

      if (imageUrl != null) {
        requestBody['files'] = FieldValue.arrayRemove([imageUrl]);
      }

      await docRef.update(requestBody);
      data = docRef.id;
      logger.i('InvoiceService - softDeleteInvoice is successful ${docRef.id}');
    } catch (error, stackTrace) {
      hasError = true;
      logger
          .e('InvoiceService - softDeleteInvoice failed\n$error\n$stackTrace');
      SentryUtil.error(
          'InvoiceProvider.softDeleteInvoice error: Invoice ID $invoiceId, imageUrl $imageUrl',
          'InvoiceProvider class',
          error,
          stackTrace);
    }

    return Response(data: data, hasError: hasError);
  }
}

class MockInvoiceService implements InvoiceService {
  @override
  Future<Response<String?>> addInvoiceComment(
      String invoiceId, String comment) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String>> createInvoice(Invoice invoice,
      {List<Uint8List>? newImagesToUpload}) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String?>> deleteInvoiceImage(
      String invoiceId, String imageUrl) {
    return Future.value(Response(data: '1'));
  }

  @override
  Stream<List<Invoice>> getInvoicesStream() {
    return Stream.value([]);
  }

  @override
  Future<Response<String?>> softDeleteInvoice(String invoiceId,
      [String? imageUrl]) {
    return Future.value(Response(data: '1'));
  }

  @override
  Future<Response<String>> updateInvoice(Invoice invoice,
      {List<Uint8List>? newImagesToUpload}) {
    return Future.value(Response(data: '1'));
  }
}
