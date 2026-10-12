bool readyForPickup(Map<String, dynamic> order) =>
    order['status'] == 'Fabricado' && order['metodoEnvio'] == 'Retirar na loja';

String cancellationSummary(Map<String, dynamic> order) {
  Map? event = order['cancelamento'] is Map
      ? order['cancelamento'] as Map
      : null;
  if (event == null) {
    for (final entry in (order['historico'] as List? ?? []).reversed) {
      if (entry is Map &&
          entry['detalhes'] is Map &&
          entry['detalhes']['novo'] == 'Cancelado') {
        event = entry;
        break;
      }
    }
  }
  return event == null
      ? 'Responsável pelo cancelamento não registrado neste pedido antigo.'
      : 'Cancelado por: ${event['autor'] ?? event['usuarioId'] ?? 'Responsável não identificado'}';
}

String pickupReadyMessage(String id, Map<String, dynamic> order) {
  final customer = order['cliente'] is Map ? order['cliente'] as Map : {};
  final name = '${customer['nome'] ?? order['nomeCliente'] ?? 'cliente'}';
  return '${order['pedidoTeste'] == true ? '[PEDIDO DE TESTE]\n' : ''}'
      'Olá, $name! Seu pedido #$id da Benta Laços foi fabricado e está pronto para retirar. '
      '${'${order['instrucoesEntrega'] ?? ''}'.trim().isEmpty ? 'Entre em contato para combinar o horário da retirada.' : order['instrucoesEntrega']} Obrigada!';
}

String customerOrderProgress(
  Map<String, dynamic> order,
) => switch (order['status']) {
  'Pendente' => 'Recebemos seu pedido. Ele aguarda aceitação.',
  'Aceito' => 'Seu pedido foi aceito e está em fabricação.',
  'Fabricado' =>
    order['metodoEnvio'] == 'Retirar na loja'
        ? 'Seu pedido está pronto para retirar! Combine o horário com a Benta Laços.'
        : 'Seu pedido foi fabricado e está pronto para o envio.',
  'Enviado' => 'Seu pedido está a caminho.',
  'Entregue' =>
    'Seu pedido foi entregue. Obrigada por comprar com a Benta Laços!',
  'Cancelado' => 'Este pedido foi cancelado.',
  _ => 'Acompanhe aqui as atualizações do seu pedido.',
};
