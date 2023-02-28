import 'update_finder_locator.dart'
    if (dart.library.js) 'update_finder_web.dart'
    if (dart.library.io) 'update_finder_mobile.dart';

abstract class UpdateFinder {
  static UpdateFinder? _instance;

  static bool isUpdateFound = false;

  static UpdateFinder? get instance {
    _instance ??= getUpdateFinder();
    return _instance;
  }

  void init();

  void install();
}
