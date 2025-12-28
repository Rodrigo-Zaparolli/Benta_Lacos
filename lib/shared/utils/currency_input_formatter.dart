// lib/utils/currency_input_formatter.dart
import 'package:flutter/services.dart';

class CurrencyInputFormatter extends TextInputFormatter {
  // Formata enquanto digita no padrão 0,00
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    String onlyDigits = newValue.text.replaceAll(RegExp(r'[^0-9]'), '');
    if (onlyDigits.isEmpty) {
      return newValue.copyWith(text: '');
    }

    final int value = int.parse(onlyDigits);
    final double doubleValue = value / 100.0;
    final String newText = doubleValue.toStringAsFixed(2).replaceAll('.', ',');

    return TextEditingValue(
      text: newText,
      selection: TextSelection.collapsed(offset: newText.length),
    );
  }
}
