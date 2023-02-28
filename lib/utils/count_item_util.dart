class CountItemUtil {
  static String parseCalc(String calc) {
    var newCalc = '';
    final previousDataPattern = RegExp(r'1\,\*24|\,\+\,$|1\✕24|\✕');
    if (calc.contains(previousDataPattern)) {
      final endingPlusCharPattern = RegExp(r'\,\+\,$');
      newCalc = calc.replaceAll(endingPlusCharPattern, '');
      final plusOperatorPattern = RegExp(r'\,\+\,');
      newCalc = newCalc.replaceAll(plusOperatorPattern, ' + ');
      final previousx24Pattern = RegExp(r'1\,\*24|1\✕24');
      newCalc = newCalc.replaceAll(previousx24Pattern, '1×24');
      final multiplierChar = RegExp(r'\✕');
      newCalc = newCalc.replaceAll(multiplierChar, '×');
    } else {
      newCalc =
          calc.replaceAll(RegExp(r'\,+\+\,+|(\s+)?\,+\+\,+(\s+)?'), ' + ');
    }
    return newCalc;
  }
}
