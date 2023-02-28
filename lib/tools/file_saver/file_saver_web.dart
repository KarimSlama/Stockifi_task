// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'dart:convert';

import 'file_saver.dart';

class FileSaverWeb extends FileSaver {
  @override
  Future<void> save(String fileName, List<int> bytes) async {
    final url = "data:application/octet-stream;base64,${base64Encode(bytes)}";
    html.AnchorElement(href: url)
      ..setAttribute("download", fileName)
      ..click();
  }
}

FileSaver getFileSaver() => FileSaverWeb();
