import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:url_launcher/url_launcher.dart';

export 'package:url_launcher/link.dart';

class UrlLauncherUtil {
  static Future<void> launchUrlString(String url) async {
    try {
      final validLaunch = await canLaunchUrl(Uri.parse(url));
      if (validLaunch) {
        await launchUrl(Uri.parse(url));
      }
    } catch (e, s) {
      logger.e('URL Launch Failed\n$e\n$s');
    }
  }
}
