import 'package:logger/logger.dart';
export 'package:logger/logger.dart';

const shouldLogAll = true;

Logger get logger {
  return Logger(
    filter: shouldLogAll ? null : CustomFilter(),
    printer: PrettyPrinter(
      methodCount: 1,
      errorMethodCount: 5,
      lineLength: 50,
      colors: true,
      printTime: false,
      printEmojis: true,
    ),
  );
}

class CustomFilter extends LogFilter {
  @override
  bool shouldLog(LogEvent event) {
    var shouldLog = false;
    assert(() {
      shouldLog = event.level.index >= Level.warning.index;
      return true;
    }());
    return shouldLog;
  }
}
