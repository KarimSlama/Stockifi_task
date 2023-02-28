import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:stocklio_flutter/utils/logger_util.dart';
import 'package:stocklio_flutter/utils/sentry_util.dart';

class ParseUtil {
  static String _errorMessage(String methodName, dynamic value) {
    return '$methodName error: $value is of type ${value.runtimeType}';
  }

  static num toNum(dynamic value) {
    if (value is num) return value;
    try {
      if (value is String) {
        final str = value;
        if (str.isNotEmpty) {
          return num.parse(str);
        }
      }
    } catch (error, stackTrace) {
      final message = _errorMessage('ParseUtil.toNum', value);
      SentryUtil.error(message, 'ParseUtil class', error, stackTrace);
      logger.e(message);
    }
    return 0;
  }

  static int toInt(dynamic value) {
    if (value is int) return value;

    ///TODO: do we need to truncate or round off the value?
    ///cases include value 12.68 which is a double
    if (value is double) return value.toInt();
    try {
      return int.tryParse(value) ?? 0;
    } catch (error, stackTrace) {
      final message = _errorMessage('ParseUtil.toInt', value);
      SentryUtil.error(message, 'ParseUtil class', error, stackTrace);
      logger.e(message + stackTrace.toString());
    }
    return 0;
  }

  static double toDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    try {
      return double.parse(value);
    } catch (error, stackTrace) {
      final message = _errorMessage('ParseUtil.toDouble', value);
      SentryUtil.error(message, 'ParseUtil class', error, stackTrace);
      logger.e(message);
    }
    return 0;
  }

  static DateTime? dateTimeFromTimestamp(dynamic value) {
    if (value == null || value is DateTime) return value;
    try {
      return (value as Timestamp).toDate();
    } catch (error, stackTrace) {
      final message = _errorMessage('ParseUtil.dateTimeFromTimestamp', value);
      SentryUtil.error(message, 'ParseUtil class', error, stackTrace);
      logger.e(message);
    }
    return DateTime.now();
  }

  static Timestamp? timestampToDateTime(dynamic value) {
    if (value == null || value is Timestamp) return value;
    try {
      return Timestamp.fromDate(value);
    } catch (error, stackTrace) {
      final message = _errorMessage('ParseUtil.timestampToDateTime', value);
      SentryUtil.error(message, 'ParseUtil class', error, stackTrace);
      logger.e(message);
    }
    return Timestamp.fromDate(DateTime.now());
  }
}
