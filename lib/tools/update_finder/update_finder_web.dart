// ignore: avoid_web_libraries_in_flutter
import 'dart:html' as html;

import 'update_finder.dart';

class UpdateFinderWeb extends UpdateFinder {
  @override
  void init() {
    html.window.onMessage.listen((event) {
      final message = event.data;
      if (message == 'updatefound') {
        UpdateFinder.isUpdateFound = true;
      }
    });
  }

  @override
  void install() {
    html.window.location.reload();
  }
}

UpdateFinder getUpdateFinder() => UpdateFinderWeb();
