import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';

import '../widgets/common/confirm.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';

class StringUtil {
  static void showLongText(
    BuildContext context,
    String text,
    Function(bool value) setIsPressed,
  ) {
    setIsPressed(true);
    showToast(context, text);
  }

  static void truncateLongText(
    Function(bool value) setIsPressed,
  ) {
    setIsPressed(false);
  }

  static String formatNumber(String locale, num number, [int? decimalDigits]) {
    final targetLocale = locale == 'us' ? 'en_US' : 'de_DE';
    final string = NumberFormat.currency(
      symbol: '',
      locale: targetLocale,
      decimalDigits: 2,
    ).format(number);

    return string;
  }

  static bool isDouble(String s) {
    return double.tryParse(s) != null;
  }

  static bool isInt(String s) {
    return int.tryParse(s) != null;
  }

  static AppLocalizations localize(BuildContext context) =>
      AppLocalizations.of(context)!;

  static String formatDate(DateTime? date) {
    if (date == null) return 'N/A';
    return DateFormat('dd/MM').add_Hm().format(date);
  }

  static String toPercentage(num value) => '${value * 100}%';
}

String removeDecimalZeroFormat(String string) {
  RegExp regex = RegExp(r'([.]*0*0)(?!.*\d)');
  return string.replaceAll(regex, '');
}
