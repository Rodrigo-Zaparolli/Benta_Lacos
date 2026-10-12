import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'pt_BR',
  symbol: 'R\$',
  decimalDigits: 2,
);
List<String> orderSearchTokens(String id, String name) {
  final values = {
    normalizeSearch(id),
    normalizeSearch(name),
    ...normalizeSearch(name).split(' '),
  };
  return {
    for (final value in values)
      for (var i = 1; i <= value.length && i <= 100; i++) value.substring(0, i),
  }.toList();
}

String formatMoney(num value) => _currency.format(value);

String whatsappPhone(String value) {
  final digits = value.replaceAll(RegExp(r'\D'), '');
  return digits.length <= 11 ? '55$digits' : digits;
}

String normalizeSearch(String value) {
  const accented = 'áàâãäéèêëíìîïóòôõöúùûüç';
  const plain = 'aaaaaeeeeiiiiooooouuuuc';
  var result = value.toLowerCase().trim();
  for (var i = 0; i < accented.length; i++) {
    result = result.replaceAll(accented[i], plain[i]);
  }
  return result;
}
