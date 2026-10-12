import 'package:cloud_firestore/cloud_firestore.dart';
import '../../shared/utils/store_format.dart';

DateTime? recordDate(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  return DateTime.tryParse(value?.toString() ?? '');
}

bool isConfirmedOrder(Map<String, dynamic> order) =>
    order['fluxoPedido'] == 'fabricacao'
    ? (order['pagamentoConfirmado'] != null ||
              order['pagamentoLegado'] == true) &&
          !['Cancelado', 'Excluido'].contains(order['status'])
    : [
        'pago',
        'enviado',
        'entregue',
      ].contains(normalizeSearch('${order['status'] ?? ''}'));

bool inDateRange(Map<String, dynamic> record, DateTime? start, DateTime? end) {
  if (start == null && end == null) return true;
  final date = recordDate(
    record['dataPedido'] ?? record['data'] ?? record['dataHora'],
  );
  if (date == null) return false;
  final from = start == null
      ? null
      : DateTime(start.year, start.month, start.day);
  final until = end == null ? null : DateTime(end.year, end.month, end.day + 1);
  return (from == null || !date.isBefore(from)) &&
      (until == null || date.isBefore(until));
}

String paymentCategory(dynamic value) {
  final method = normalizeSearch('$value');
  if (method.contains('pix')) return 'Pix';
  if (method.contains('credito') && method.contains('debito'))
    return 'Cartão a confirmar';
  if (method.contains('credito')) return 'Crédito';
  if (method.contains('debito')) return 'Débito';
  if (method.contains('cartao')) return 'Cartão a confirmar';
  if (method.contains('dinheiro')) return 'Dinheiro';
  if (method == 'outro') return 'Outro';
  return 'Não informado';
}

class AdminMetrics {
  final List<Map<String, dynamic>> orders;
  final List<Map<String, dynamic>> confirmed;
  final double revenue;
  final int units;
  final double pendingValue;
  final Map<String, double> payments;
  final Map<String, int> preferences;
  final Map<DateTime, double> daily;
  final Map<String, int> products;
  final double fees;

  AdminMetrics._(
    this.orders,
    this.confirmed,
    this.revenue,
    this.units,
    this.pendingValue,
    this.payments,
    this.preferences,
    this.daily,
    this.products,
    this.fees,
  );

  factory AdminMetrics.fromOrders(
    List<Map<String, dynamic>> source, {
    DateTime? start,
    DateTime? end,
  }) {
    final orders = source
        .where((o) => o['pedidoTeste'] != true && inDateRange(o, start, end))
        .toList();
    final confirmed = orders.where(isConfirmedOrder).toList();
    double revenue = 0, pending = 0, fees = 0;
    int units = 0;
    final payments = <String, double>{}, daily = <DateTime, double>{};
    final preferences = <String, int>{}, products = <String, int>{};
    for (final order in orders) {
      final total = (order['total'] as num? ?? 0).toDouble();
      if (!isConfirmedOrder(order) &&
          ![
            'cancelado',
            'excluido',
          ].contains(normalizeSearch('${order['status']}'))) {
        pending += total;
        final method = paymentCategory(order['metodoPagamento']);
        preferences[method] = (preferences[method] ?? 0) + 1;
      }
      if (!isConfirmedOrder(order)) continue;
      revenue += total;
      fees += (order['taxas'] as num? ?? 0).toDouble();
      final method = paymentCategory(
        order['pagamentoConfirmado'] ?? order['metodoPagamento'],
      );
      payments[method] = (payments[method] ?? 0) + total;
      final date = recordDate(
        order['dataPedido'] ?? order['data'] ?? order['dataHora'],
      );
      if (date != null) {
        final day = DateTime(date.year, date.month, date.day);
        daily[day] = (daily[day] ?? 0) + total;
      }
      for (final raw in order['itens'] as List? ?? []) {
        final item = Map<String, dynamic>.from(raw as Map);
        final quantity = (item['quantidade'] as num? ?? 0).toInt();
        if (quantity < 1) continue;
        units += quantity;
        final name = '${item['nome'] ?? 'Produto'}';
        products[name] = (products[name] ?? 0) + quantity;
      }
    }
    return AdminMetrics._(
      orders,
      confirmed,
      revenue,
      units,
      pending,
      payments,
      preferences,
      daily,
      products,
      fees,
    );
  }
}
