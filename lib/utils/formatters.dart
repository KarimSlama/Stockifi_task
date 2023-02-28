import 'package:flutter/services.dart';

class DecimalInputFormatter extends TextInputFormatter {
  final int decimalRange;

  DecimalInputFormatter({this.decimalRange = 2}) : assert(decimalRange > 0);

  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    var newText = newValue.text.replaceAll(',', '.');
    var newSelection = newValue.selection;

    final pattern = RegExp(r'(\d+\.?)|(\.?\d+)|(\.?)');
    newText = pattern
        .allMatches(newText)
        .map<String>((Match match) => match.group(0) ?? '')
        .join();

    if (newText.startsWith('.')) {
      newText = '0.';
      newSelection = newSelection.copyWith(
        baseOffset: newText.length,
        extentOffset: newText.length,
      );
    } else if (newText.contains('.')) {
      if (newText.substring(newText.indexOf('.') + 1).length > decimalRange) {
        newText = oldValue.text;
      } else if (newText.split('.').length > 2) {
        final split = newText.split('.');
        newText = '${split[0]}.${split[1]}';
      }
    }

    return TextEditingValue(
      text: newText,
      selection: newSelection,
      composing: TextRange.empty,
    );
  }
}
