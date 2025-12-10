import 'package:flutter/services.dart';
import 'package:intl/intl.dart';

class ThousandsSeparatorInputFormatter extends TextInputFormatter {
  final NumberFormat _formatter;

  ThousandsSeparatorInputFormatter({String locale = 'en_US'}) : _formatter = NumberFormat.decimalPattern(locale);

  String _onlyDigits(String s) => s.replaceAll(RegExp('[^0-9]'), '');

  @override
  TextEditingValue formatEditUpdate(TextEditingValue oldValue, TextEditingValue newValue) {
    // If pasted or removed non-digit chars, normalize
    final newDigits = _onlyDigits(newValue.text);

    if (newDigits.isEmpty) {
      return TextEditingValue(text: '', selection: TextSelection.collapsed(offset: 0));
    }

    // format number
    String formatted;
    try {
      final parsed = int.parse(newDigits);
      formatted = _formatter.format(parsed);
    } catch (_) {
      // Fallback in case of parse error (very large numbers)
      // Insert separators manually
      formatted = _manualFormat(newDigits);
    }

    // compute caret position: count digits before newValue.selection
    final selectionIndex = newValue.selection.baseOffset;
    final digitsBeforeCursor = _countDigitsBefore(newValue.text, selectionIndex);

    // set new cursor by finding position after digitsBeforeCursor in formatted
    int newCursorPosition = _cursorPositionFromDigits(formatted, digitsBeforeCursor);

    return TextEditingValue(
      text: formatted,
      selection: TextSelection.collapsed(offset: newCursorPosition),
    );
  }

  int _countDigitsBefore(String text, int index) {
    if (index <= 0) return 0;
    final sub = text.substring(0, index);
    return _onlyDigits(sub).length;
  }

  int _cursorPositionFromDigits(String formatted, int digitsBefore) {
    if (digitsBefore <= 0) return 0;
    int count = 0;
    for (int i = 0; i < formatted.length; i++) {
      if (RegExp('[0-9]').hasMatch(formatted[i])) {
        count++;
        if (count >= digitsBefore) return i + 1; // cursor after this digit
      }
    }
    return formatted.length;
  }

  String _manualFormat(String digits) {
    final sb = StringBuffer();
    int len = digits.length;
    int firstGroup = len % 3;
    if (firstGroup == 0) firstGroup = 3;
    sb.write(digits.substring(0, firstGroup));
    for (int i = firstGroup; i < len; i += 3) {
      sb.write(',');
      sb.write(digits.substring(i, i + 3));
    }
    return sb.toString();
  }
}

