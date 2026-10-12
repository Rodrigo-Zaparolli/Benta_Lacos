import 'package:flutter_test/flutter_test.dart';
import 'package:benta_lacos/domain/models/product_model.dart';
import 'package:benta_lacos/domain/services/admin_metrics.dart';
import 'package:benta_lacos/domain/services/order_messages.dart';
import 'package:benta_lacos/domain/services/order_policy.dart';
import 'package:benta_lacos/shared/utils/store_format.dart';

void main() {
  test(
    'made-to-order availability uses order limit instead of ready stock',
    () {
      final product = Product.fromMap({
        'name': 'Laço',
        'price': 10,
        'quantity': 0,
        'madeToOrder': true,
        'productionDays': 4,
        'orderCapacity': 3,
      }, 'p');
      expect(product.available, isTrue);
      expect(product.purchaseLimit, 3);
      expect(product.copyWith(orderCapacity: 0).available, isFalse);
      expect(Product.fromMap(product.toMap(), 'p').productionDays, 4);
      expect(product.copyWith(madeToOrder: false).available, isFalse);
    },
  );
  test('payment remains independent from fabrication stages', () {
    expect(allowedOrderStatuses('Pendente'), ['Aceito', 'Cancelado']);
    expect(allowedOrderStatuses('Aceito'), ['Fabricado', 'Cancelado']);
    final metrics = AdminMetrics.fromOrders([
      {'status': 'Aceito', 'fluxoPedido': 'fabricacao', 'total': 30},
      {
        'status': 'Fabricado',
        'fluxoPedido': 'fabricacao',
        'pagamentoConfirmado': 'Pix',
        'total': 20,
      },
      {
        'status': 'Fabricado',
        'fluxoPedido': 'fabricacao',
        'pagamentoLegado': true,
        'total': 10,
      },
    ]);
    expect(metrics.revenue, 30);
    expect(metrics.pendingValue, 30);
  });
  test('pickup message includes administrator instructions', () {
    final message = pickupReadyMessage('p', {
      'cliente': {'nome': 'Ana'},
      'instrucoesEntrega': 'Retire na Rua A, das 14h às 18h.',
    });
    expect(message, contains('Rua A'));
    expect(message, isNot(contains('combinar o horário')));
  });
  test('indexed search normalizes accents and indexes full ID prefixes', () {
    final tokens = orderSearchTokens('ABC123', 'Márcia Silva');
    expect(tokens, containsAll(['abc123', 'marcia', 'silva', 'marcia sil']));
    expect(tokens, isNot(contains('')));
  });
}
