class NumberUtil {
  static bool isInteger(num value) =>
      value is int || value == value.roundToDouble();
}
