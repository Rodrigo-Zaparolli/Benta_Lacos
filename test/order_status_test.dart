import 'package:benta_lacos/domain/services/order_policy.dart';
import 'package:benta_lacos/pages/admin/pedidos/order_status_dialog.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('store pickup removes quoted shipping and allows payment', () {
    final order = {
      'status': 'Pendente',
      'subtotal': 100.0,
      'total': 125.0,
      'valorFrete': 25.0,
      'freteACombinar': true,
    };
    final updated = {...order, ...shippingQuoteFields(order, 0, pickup: true)};
    expect(updated['total'], 100.0);
    expect(updated['valorFrete'], 0.0);
    expect(updated['metodoEnvio'], 'Retirar na loja');
    expect(updated['freteACombinar'], false);
    validateOrderTransition(updated, 'Pago', paymentMethod: 'Pix');
    final legacy = shippingQuoteFields(
      {'total': 125, 'valorFrete': 25},
      0,
      pickup: true,
    );
    expect(legacy['total'], 100.0);
  });
  Future<void> open(
    WidgetTester tester,
    Map<String, dynamic> order,
    ValueChanged<String?> onResult,
  ) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) {
            return Scaffold(
              body: TextButton(
                onPressed: () async => onResult(
                  await showDialog<String>(
                    context: context,
                    builder: (_) => OrderStatusDialog(order: order),
                  ),
                ),
                child: const Text('Abrir'),
              ),
            );
          },
        ),
      ),
    );
    await tester.tap(find.text('Abrir'));
    await tester.pumpAndSettle();
  }

  testWidgets(
    'status selector returns next status and prevents skipping payment',
    (tester) async {
      String? selected;
      await open(tester, {'status': 'Pendente'}, (value) => selected = value);
      await tester.tap(find.byType(DropdownButtonFormField<String>));
      await tester.pumpAndSettle();
      expect(find.text('Enviado'), findsNothing);
      expect(find.text('Entregue'), findsNothing);
      await tester.tap(find.text('Aceito').last);
      await tester.pumpAndSettle();
      await tester.tap(find.text('Continuar'));
      await tester.pumpAndSettle();
      expect(selected, 'Aceito');
      expect(find.byType(OrderStatusDialog), findsNothing);
    },
  );

  test('pending shipping does not block acceptance', () {
    validateOrderTransition({
      'status': 'Pendente',
      'freteACombinar': true,
    }, 'Aceito');
    expect(allowedOrderStatuses('Pendente'), isNot(contains('Pago')));
  });
}
