import 'package:flutter_test/flutter_test.dart';
import 'package:benta_lacos/domain/services/order_messages.dart';
import 'package:benta_lacos/domain/services/order_policy.dart';
import 'package:benta_lacos/domain/services/admin_metrics.dart';
import 'package:benta_lacos/domain/services/stock_policy.dart';

void main() {
  test('accept and manufacture without requiring shipping or payment', () {
    final order = {'status': 'Pendente', 'freteACombinar': true};
    validateOrderTransition(order, 'Aceito');
    validateOrderTransition({...order, 'status': 'Aceito'}, 'Fabricado');
    expect(() => validateOrderTransition(order, 'Fabricado'), throwsStateError);
  });
  test('pickup is delivered directly after manufacture', () {
    final order = {'status': 'Fabricado', 'metodoEnvio': 'Retirar na loja'};
    expect(readyForPickup(order), isTrue);
    validateOrderTransition(order, 'Entregue');
    expect(() => validateOrderTransition(order, 'Enviado'), throwsStateError);
    expect(customerOrderProgress(order), contains('pronto para retirar'));
    expect(customerOrderProgress({'status': 'Aceito'}), contains('aceito'));
  });
  test('pickup notice identifies customer and test order', () {
    final message = pickupReadyMessage('TEST123', {
      'cliente': {'nome': 'Maria'},
      'pedidoTeste': true,
    });
    expect(message, contains('Maria'));
    expect(message, contains('#TEST123'));
    expect(message, startsWith('[PEDIDO DE TESTE]'));
  });
  test('manufacture does not count as payment and stock deducts once', () {
    final order = {'fluxoPedido': 'fabricacao', 'status': 'Fabricado'};
    expect(isConfirmedOrder(order), isFalse);
    expect(isConfirmedOrder({...order, 'pagamentoConfirmado': 'Pix'}), isTrue);
    expect(
      isConfirmedOrder({
        ...order,
        'status': 'Cancelado',
        'pagamentoConfirmado': 'Pix',
      }),
      isFalse,
    );
    expect(stockDirection(deducted: false, status: 'Entregue'), -1);
    expect(stockDirection(deducted: true, status: 'Entregue'), 0);
  });
  test('cancellation shows actor from new record or historical audit', () {
    final event = {
      'autor': 'admin@loja.com',
      'detalhes': {'novo': 'Cancelado'},
    };
    expect(
      cancellationSummary({'cancelamento': event}),
      contains('admin@loja.com'),
    );
    expect(
      cancellationSummary({
        'historico': [event],
      }),
      contains('admin@loja.com'),
    );
    expect(cancellationSummary({}), contains('não registrado'));
  });
}
