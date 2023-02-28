import 'dart:async';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:mime/mime.dart';
import 'package:path/path.dart';
import 'package:excel/excel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:share_plus/share_plus.dart';
import 'package:stocklio_flutter/utils/string_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';
import 'package:stocklio_flutter/widgets/common/confirm.dart';
import 'package:path_provider/path_provider.dart';
import 'package:file_picker/file_picker.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:printing/printing.dart';

class FileUtil {
  static Future<void> saveExcel(
    BuildContext context,
    String fileName,
    Excel excel, [
    bool isDownloadable = false,
  ]) async {
    if (!isDownloadable) {
      showToast(
        context,
        StringUtil.localize(context).message_locale_report,
      );

      return;
    }

    if (kIsWeb) {
      excel.save(fileName: fileName);
      return;
    }

    final box = context.findRenderObject() as RenderBox?;
    final fileBytes = excel.save(fileName: fileName);
    final dir = await getApplicationDocumentsDirectory();
    final downloadsPath = dir.path;

    if (fileBytes != null) {
      File(join('$downloadsPath/$fileName'))
        ..createSync(recursive: true)
        ..writeAsBytesSync(excel.save()!);

      await Share.shareXFiles(
        [XFile('$downloadsPath/$fileName')],
        text: fileName,
        sharePositionOrigin: box!.localToGlobal(Offset.zero) & box.size,
      );
    }
  }

  static Future<List<Uint8List>> pickFiles(BuildContext context) async {
    var files = <Uint8List>[];
    FilePickerResult? result;

    try {
      result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        withData: true,
        allowCompression: true,
        allowMultiple: true,
        allowedExtensions: ['pdf'],
      );

      if (result != null) {
        for (var file in result.files) {
          final mime = lookupMimeType('', headerBytes: file.bytes);

          if (mime == 'application/pdf') {
            final convertedImages = await _pdfToImages(file.bytes!);
            files.addAll(convertedImages);
          } else {
            files.add(file.bytes!);
          }
        }
        logger.i('File Util - pickFiles is successful ${files.length}');
      }
    } catch (error, stackTrace) {
      logger.e('File Util - pickFiles failed $error');
      SentryUtil.error(
          'FileUtil.pickFiles error: List<Uint8List> $files, FilePickerResult $result',
          'FileUtil class',
          error,
          stackTrace);
    }
    return files;
  }

  static Future<List<Uint8List>> _pdfToImages(Uint8List bytes) async {
    var images = <Uint8List>[];

    try {
      await for (var page in Printing.raster(bytes, dpi: 140)) {
        final image = await page.toPng();
        images.add(image);
      }
    } catch (error, stackTrace) {
      logger.e('PDF to images failed $error');
      SentryUtil.error(
          'FileUtil._pdfToImages error: Uint8List $bytes, images $images',
          'FileUtil class',
          error,
          stackTrace);
    }
    return images;
  }

  static Future<Uint8List?> pickImage(BuildContext context) async {
    XFile? fromPicker;
    try {
      final status = await Permission.camera.request();

      if (status.isGranted) {
        fromPicker = await ImagePicker().pickImage(
          source: ImageSource.camera,
          maxHeight: 2000,
          maxWidth: 2000,
          imageQuality: 80,
        );

        if (fromPicker == null) return null;

        logger.i('Image Util - pickImage is successful');
        return await fromPicker.readAsBytes();
      }
    } catch (error, stackTrace) {
      logger.e('$error\nImage Util - pickImage failed');
      SentryUtil.error('FileUtil.pickImage error: XFile $fromPicker',
          'FileUtil class', error, stackTrace);
    }
    return null;
  }

  static Future<List<Uint8List>?> pickImages(BuildContext context) async {
    List<XFile>? fromPicker;
    try {
      fromPicker = await ImagePicker().pickMultiImage(
        maxHeight: 2000,
        maxWidth: 2000,
        imageQuality: 80,
      );

      var files = <Uint8List>[];

      for (var pickedFile in fromPicker) {
        files.add(await pickedFile.readAsBytes());
      }

      logger.i('Image Util - pickImages is successful');
      return files;
    } catch (error, stackTrace) {
      logger.e('$error\nImage Util - pickImages failed');
      SentryUtil.error('FileUtil.pickImage error: List<XFile> $fromPicker',
          'FileUtil class', error, stackTrace);
    }
    return null;
  }
}
