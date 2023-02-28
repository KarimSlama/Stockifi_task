// Dart Packages
import 'dart:typed_data';

// 3rd-Party Packages
import 'package:firebase_storage/firebase_storage.dart';
import 'package:get_it/get_it.dart';

// Models
import 'package:stocklio_flutter/models/cloud_storage_result.dart';
import 'package:stocklio_flutter/services/auth_service.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import 'package:uuid/uuid.dart';

// Services
import '../models/response.dart';

abstract class FileUploaderService {
  Future<Response<CloudStorageResult>> uploadImage(
    String imageFileName,
    Uint8List imageToUpload,
  );
  Future<Response<CloudStorageResult>> uploadInvoiceImage(
    String invoiceId,
    Uint8List imageToUpload,
  );
}

class FileUploaderServiceImpl implements FileUploaderService {
  late final FirebaseStorage _storage;
  late final AuthService _authService;

  FileUploaderServiceImpl({
    FirebaseStorage? storage,
    AuthService? authService,
  }) {
    _storage = storage ?? FirebaseStorage.instance;
    _authService = authService ?? GetIt.instance<AuthService>();
  }

  @override
  Future<Response<CloudStorageResult>> uploadImage(
    String imageFileName,
    Uint8List imageToUpload,
  ) async {
    var hasError = false;
    CloudStorageResult? cloudStorageResult;

    try {
      final downloadUrl = await _storage
          .ref()
          .child(imageFileName)
          .putData(imageToUpload)
          .then((snapshot) => snapshot.ref.getDownloadURL());

      cloudStorageResult = CloudStorageResult(
        downloadUrl: downloadUrl.toString(),
        fileName: imageFileName,
      );

      logger.i('FileUploaderService - uploadFile is successful $imageFileName');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'FileUploaderService - uploadFile failed $imageFileName $error\n$stackTrace');
      SentryUtil.error(
          'GlobalItemProvider.uploadImage() error: imageFileName $imageFileName, imageToUpload $imageToUpload',
          'FileUploaderService class',
          error,
          stackTrace);
    }

    return Response(data: cloudStorageResult, hasError: hasError);
  }

  @override
  Future<Response<CloudStorageResult>> uploadInvoiceImage(
    String invoiceId,
    Uint8List imageToUpload,
  ) async {
    var hasError = false;
    CloudStorageResult? cloudStorageResult;

    try {
      final uid = _authService.uid;
      var uploadPath = 'users/$uid/invoices/$invoiceId';
      var imageFileName = 'invoice_image_${invoiceId}_${const Uuid().v1()}.png';

      final uploadImageResponse =
          await uploadImage(uploadPath + imageFileName, imageToUpload);

      cloudStorageResult = uploadImageResponse.data;

      logger.i(
          'FileUploaderService - uploadInvoiceImage is successful $imageFileName');
    } catch (error, stackTrace) {
      hasError = true;
      logger.e(
          'FileUploaderService - uploadInvoiceImage failed\n$error\n$stackTrace');
      SentryUtil.error(
          'GlobalItemProvider.uploadInvoiceImage() error: invoiceId $invoiceId, imageToUpload $imageToUpload',
          'FileUploaderService class',
          error,
          stackTrace);
    }

    return Response(data: cloudStorageResult, hasError: hasError);
  }
}

class MockFileUploaderService implements FileUploaderService {
  @override
  Future<Response<CloudStorageResult>> uploadImage(
    String imageFileName,
    Uint8List imageToUpload,
  ) {
    return Future.value(
      Response<CloudStorageResult>(
        data: CloudStorageResult(downloadUrl: 'testUrl'),
        hasError: false,
      ),
    );
  }

  @override
  Future<Response<CloudStorageResult>> uploadInvoiceImage(
      String invoiceId, Uint8List imageToUpload) {
    return Future.value(
      Response<CloudStorageResult>(
        data: CloudStorageResult(downloadUrl: 'testUrl'),
        hasError: false,
      ),
    );
  }
}
