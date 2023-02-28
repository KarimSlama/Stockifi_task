import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import 'file_saver.dart';

class FileSaverMobile extends FileSaver {
  @override
  Future<void> save(String fileName, List<int> bytes) async {
    final dir = await getApplicationDocumentsDirectory();
    final downloadsPath = dir.path;

    File(join('$downloadsPath/$fileName'))
      ..createSync(recursive: true)
      ..writeAsBytesSync(bytes);

    await Share.shareXFiles(
      [XFile('$downloadsPath/$fileName')],
      text: fileName,
    );
  }
}

FileSaver getFileSaver() => FileSaverMobile();
