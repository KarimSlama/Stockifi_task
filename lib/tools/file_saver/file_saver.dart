import 'file_saver_locator.dart'
    if (dart.library.js) 'file_saver_web.dart'
    if (dart.library.io) 'file_saver_mobile.dart';

abstract class FileSaver {
  static FileSaver? _instance;

  static FileSaver? get instance {
    _instance ??= getFileSaver();
    return _instance;
  }

  Future<void> save(String fileName, List<int> bytes);
}
