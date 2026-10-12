const confirmedPaymentMethods = [
  'Pix',
  'Crédito',
  'Débito',
  'Dinheiro',
  'Outro',
];

List<String> allowedOrderStatuses(String current, {bool pickup = false}) =>
    switch (current) {
      'Pendente' => ['Aceito', 'Cancelado'],
      'Aceito' => ['Fabricado', 'Cancelado'],
      'Pago' => ['Fabricado', 'Enviado', 'Cancelado'],
      'Fabricado' =>
        pickup ? ['Entregue', 'Cancelado'] : ['Enviado', 'Cancelado'],
      'Enviado' => ['Entregue', 'Cancelado'],
      _ => [],
    };

Map<String, dynamic> shippingQuoteFields(
  Map<String, dynamic> order,
  double amount, {
  bool pickup = false,
}) {
  final subtotal =
      (order['subtotal'] as num?)?.toDouble() ??
      ((order['total'] as num? ?? 0).toDouble() -
          (order['valorFrete'] as num? ?? 0).toDouble());
  final shipping = pickup ? 0.0 : amount;
  return {
    'valorFrete': shipping,
    'freteACombinar': false,
    'total': subtotal + shipping,
    if (pickup) 'metodoEnvio': 'Retirar na loja',
  };
}

void validateOrderTransition(
  Map<String, dynamic> order,
  String next, {
  String? paymentMethod,
}) {
  final current = '${order['status'] ?? 'Pendente'}';
  if (current == next) return;
  if (next == 'Pago' && ['Pendente', 'Aceito', 'Fabricado'].contains(current)) {
    if (!confirmedPaymentMethods.contains(paymentMethod))
      throw StateError('Informe o meio de pagamento recebido.');
    if (order['freteACombinar'] == true)
      throw StateError(
        'Informe o frete combinado antes de confirmar o pagamento.',
      );
    return;
  }
  if (!allowedOrderStatuses(
    current,
    pickup: order['metodoEnvio'] == 'Retirar na loja',
  ).contains(next))
    throw StateError(
      'Esta alteração de status não é permitida. Reabra o pedido para conferir seu estado atual.',
    );
  if (next == 'Pago' && !confirmedPaymentMethods.contains(paymentMethod))
    throw StateError('Informe o meio de pagamento recebido.');
  if (next == 'Pago' && order['freteACombinar'] == true)
    throw StateError(
      'Informe o frete combinado antes de confirmar o pagamento.',
    );
}
