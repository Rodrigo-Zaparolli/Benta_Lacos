import 'package:cloud_firestore/cloud_firestore.dart';
import '../providers/cart_provider.dart';
import 'stock_policy.dart';
import 'order_policy.dart';
import 'admin_audit.dart';
import '../../core/config/store_environment.dart';
import 'order_messages.dart';
import '../../shared/utils/store_format.dart';

/// Pending requests do not reserve stock. Confirmation updates stock atomically.
class OrderService {
  final FirebaseFirestore firestore;
  final bool testMode;
  OrderService(this.firestore, {this.testMode = StoreEnvironment.isTest});

  // The web SDK wraps Dart callback errors in a JavaScript error. Keep the
  // original validation error so checkout can explain why the order was refused.
  Future<T> _runValidatedTransaction<T>(
    Future<T> Function(Transaction) action,
  ) async {
    StateError? validationError;
    try {
      return await firestore.runTransaction<T>((transaction) async {
        validationError = null;
        try {
          return await action(transaction);
        } on StateError catch (error) {
          validationError = error;
          rethrow;
        }
      });
    } catch (_) {
      if (validationError != null) throw validationError!;
      rethrow;
    }
  }

  Future<Map<String, dynamic>> createRequest({
    required String id,
    required String uid,
    required List<CartItem> items,
    required Map<String, dynamic> customer,
    required String delivery,
    required String payment,
  }) => _runValidatedTransaction((transaction) async {
    final reference = firestore
        .collection(StoreEnvironment.collectionName('pedidos'))
        .doc(id);
    final existing = await transaction.get(reference);
    if (existing.exists) {
      if (existing.data()?['clienteId'] != uid)
        throw StateError('Não foi possível registrar este pedido.');
      return existing.data()!;
    }
    if (items.isEmpty) throw StateError('Selecione pelo menos um produto.');
    if (items.length > 9)
      throw StateError(
        'Cada pedido pode ter até 9 produtos diferentes. Divida os itens em dois pedidos.',
      );
    final lines = <Map<String, dynamic>>[];
    double subtotal = 0;
    for (final item in items) {
      final snapshot = await transaction.get(
        firestore
            .collection(StoreEnvironment.collectionName('produtos'))
            .doc(item.product.id),
      );
      final product = snapshot.data();
      if (product == null ||
          product['isArchived'] == true ||
          item.quantity < 1 ||
          item.quantity > 100 ||
          (!testMode &&
              (product[product['madeToOrder'] == true
                              ? 'orderCapacity'
                              : 'quantity']
                          as num? ??
                      0) <
                  item.quantity)) {
        throw StateError(
          'Estoque insuficiente para ${item.product.name}. Revise o carrinho.',
        );
      }
      final price = (product['price'] as num).toDouble();
      if (!price.isFinite || price < 0)
        throw StateError(
          'Preço indisponível para ${item.product.name}. Consulte o atendimento.',
        );
      if (price != item.product.price)
        throw StateError(
          'O preço de ${item.product.name} mudou. Remova o item e adicione-o novamente.',
        );
      subtotal += price * item.quantity;
      lines.add({
        'id': snapshot.id,
        'nome': product['name'],
        'preco': price,
        'quantidade': item.quantity,
        'imageUrl': product['imageUrl'],
        'categoria': product['category'],
        'sobEncomenda': product['madeToOrder'] == true,
        'prazoDias': product['madeToOrder'] == true
            ? (product['productionDays'] ?? 7)
            : 0,
      });
    }
    final data = <String, dynamic>{
      'pedidoId': id,
      'clienteId': uid,
      'nomeCliente': customer['nome'],
      'buscaTokens': orderSearchTokens(id, '${customer['nome']}'),
      'produtoIds': lines.map((line) => line['id']).toList(),
      'arquivado': false,
      'cliente': customer,
      'enderecoExibicao': customer['endereco'],
      'total': subtotal,
      'subtotal': subtotal,
      'valorFrete': delivery == 'Retirar na loja' ? 0.0 : null,
      'freteACombinar': delivery != 'Retirar na loja',
      'itens': lines,
      'metodoPagamento': payment,
      'metodoEnvio': delivery,
      'status': 'Pendente',
      'canal': 'WhatsApp',
      'estoqueFluxo': 'confirmacao',
      'estoqueBaixado': false,
      'fluxoPedido': 'fabricacao',
      if (testMode) 'pedidoTeste': true,
      'dataPedido': FieldValue.serverTimestamp(),
    };
    transaction.set(reference, data);
    for (final line in lines) {
      transaction.set(reference.collection('itens').doc('${line['id']}'), {
        'clienteId': uid,
        'item': line,
      });
    }
    for (final item in items) {
      transaction.delete(
        firestore
            .collection(StoreEnvironment.collectionName('usuarios'))
            .doc(uid)
            .collection('carrinho')
            .doc(item.product.id),
      );
      transaction.delete(
        firestore
            .collection(StoreEnvironment.collectionName('usuarios'))
            .doc(uid)
            .collection('favoritos')
            .doc(item.product.id),
      );
    }
    return data;
  });

  Future<void> changeStatus(
    String id,
    String status, {
    String? paymentMethod,
    String? trackingCode,
    bool preserveProductionStatus = false,
    String? cancellationReason,
    String? requestedBy,
  }) => _runValidatedTransaction((transaction) async {
    final reference = firestore
        .collection(StoreEnvironment.collectionName('pedidos'))
        .doc(id);
    final snapshot = await transaction.get(reference);
    final order = snapshot.data();
    if (order == null) throw StateError('Pedido não encontrado.');
    final preserve =
        (preserveProductionStatus || order['fluxoPedido'] == 'fabricacao') &&
        status == 'Pago' &&
        [
          'Pendente',
          'Aceito',
          'Fabricado',
          'Enviado',
          'Entregue',
        ].contains(order['status']);
    if (preserve) {
      if (!confirmedPaymentMethods.contains(paymentMethod))
        throw StateError('Informe o meio de pagamento recebido.');
      if (order['freteACombinar'] == true)
        throw StateError(
          'Informe o frete ou defina retirada antes de confirmar o pagamento.',
        );
    } else {
      validateOrderTransition(order, status, paymentMethod: paymentMethod);
    }
    if (!preserve && order['status'] == status) return;
    final recordedStatus = preserve ? order['status'] : status;
    if (status == 'Cancelado' && (cancellationReason?.trim().isEmpty ?? true))
      throw StateError('Informe o motivo do cancelamento.');
    final event = auditEntry(
      preserve ? 'Pagamento confirmado' : 'Status alterado',
      details: {
        'anterior': order['status'],
        'novo': recordedStatus,
        if (status == 'Cancelado') 'motivo': cancellationReason!.trim(),
        if (status == 'Cancelado') 'solicitadoPor': requestedBy ?? 'Loja',
        if (status == 'Pago') 'pagamento': paymentMethod,
        if (status == 'Enviado') 'rastreio': trackingCode?.trim() ?? '',
      },
    );
    final metadata = <String, dynamic>{
      'status': recordedStatus,
      if (order['fluxoPedido'] != 'fabricacao' &&
          ['Pago', 'Enviado', 'Entregue'].contains(order['status']))
        'pagamentoLegado': true,
      if (status == 'Cancelado') 'cancelamento': event,
      if (status == 'Cancelado' &&
          (order['pagamentoConfirmado'] != null ||
              order['pagamentoLegado'] == true ||
              ['Pago', 'Enviado', 'Entregue'].contains(order['status'])))
        'reembolso': 'A verificar',
      if (status == 'Aceito' || status == 'Fabricado')
        'fluxoPedido': 'fabricacao',
      if (status == 'Aceito') 'dataAceite': FieldValue.serverTimestamp(),
      if (status == 'Aceito' && order['previsaoConclusao'] == null)
        'previsaoConclusao': Timestamp.fromDate(
          DateTime.now().add(
            Duration(
              days: (order['itens'] as List? ?? []).whereType<Map>().fold<int>(
                0,
                (days, item) => (item['prazoDias'] as num? ?? 0).toInt() > days
                    ? (item['prazoDias'] as num).toInt()
                    : days,
              ),
            ),
          ),
        ),
      if (status == 'Fabricado') 'dataFabricacao': FieldValue.serverTimestamp(),
      if (status == 'Fabricado' && order['metodoEnvio'] == 'Retirar na loja')
        'avisoRetirada': {
          'status': 'aguardando_envio',
          'canal': 'WhatsApp',
          'texto': pickupReadyMessage(id, order),
        },
      'updatedAt': FieldValue.serverTimestamp(),
      if (status == 'Pago') 'pagamentoConfirmado': paymentMethod,
      if (status == 'Pago') 'dataPagamento': FieldValue.serverTimestamp(),
      if (status == 'Enviado') 'codigoRastreio': trackingCode?.trim() ?? '',
      'historico': FieldValue.arrayUnion([event]),
    };
    // Older requests already deducted stock at checkout.
    if (order['pedidoTeste'] == true ||
        order['estoqueFluxo'] != 'confirmacao') {
      transaction.update(reference, metadata);
      return;
    }
    final deducted = order['estoqueBaixado'] == true;
    if ((status == 'Pago' || status == 'Enviado') &&
        order['freteACombinar'] == true) {
      throw StateError(
        'Informe o frete combinado antes de confirmar o pedido.',
      );
    }
    final direction = stockDirection(deducted: deducted, status: status);
    final updates = <DocumentReference<Map<String, dynamic>>, int>{};
    if (direction != 0) {
      for (final line in List<Map<String, dynamic>>.from(order['itens'])) {
        if (line['sobEncomenda'] == true) continue;
        final productRef = firestore
            .collection(StoreEnvironment.collectionName('produtos'))
            .doc(line['id'] as String);
        final product = await transaction.get(productRef);
        if (!product.exists)
          throw StateError(
            'Produto removido. Revise este pedido antes de alterar o status.',
          );
        final available = (product.data()?['quantity'] as num? ?? 0).toInt();
        final quantity = (line['quantidade'] as num).toInt();
        final next = checkedStock(
          available,
          quantity,
          direction,
          line['nome'] as String,
        );
        updates[productRef] = next;
      }
    }
    for (final entry in updates.entries) {
      transaction.update(entry.key, {
        'quantity': entry.value,
        'updatedAt': FieldValue.serverTimestamp(),
        'historico': FieldValue.arrayUnion([
          auditEntry(
            'Estoque movimentado pelo pedido',
            details: {
              'pedido': id,
              'quantidadeFinal': entry.value,
              'status': status,
            },
          ),
        ]),
      });
    }
    transaction.update(reference, {
      ...metadata,
      if (direction != 0) 'estoqueBaixado': direction == -1,
    });
  });

  Future<void> setStorePickup(String id) => quoteShipping(id, 0, pickup: true);

  Future<void> quoteShipping(
    String id,
    double amount, {
    bool pickup = false,
  }) async {
    if (!amount.isFinite || amount < 0)
      throw StateError('Informe um frete válido.');
    await _runValidatedTransaction((t) async {
      final ref = firestore
          .collection(StoreEnvironment.collectionName('pedidos'))
          .doc(id);
      final snapshot = await t.get(ref);
      final order = snapshot.data();
      if (order == null ||
          !['Pendente', 'Aceito', 'Fabricado'].contains(order['status']) ||
          order['pagamentoConfirmado'] != null)
        throw StateError(
          'A entrega pode ser ajustada antes da confirmação do pagamento ou do envio.',
        );
      t.update(ref, {
        ...shippingQuoteFields(order, amount, pickup: pickup),
        'updatedAt': FieldValue.serverTimestamp(),
        'historico': FieldValue.arrayUnion([
          auditEntry(
            pickup ? 'Retirada na loja definida' : 'Frete informado',
            details: {'valor': pickup ? 0.0 : amount},
          ),
        ]),
      });
    });
  }

  Future<void> setArchived(String id, bool archived) => firestore
      .collection(StoreEnvironment.collectionName('pedidos'))
      .doc(id)
      .update({
        'arquivado': archived,
        'updatedAt': FieldValue.serverTimestamp(),
        'historico': FieldValue.arrayUnion([
          auditEntry(archived ? 'Pedido arquivado' : 'Pedido restaurado'),
        ]),
      });

  Future<void> markPickupNoticeSent(String id) => firestore
      .collection(StoreEnvironment.collectionName('pedidos'))
      .doc(id)
      .update({
        'avisoRetirada.status': 'enviado_manual',
        'avisoRetirada.data': FieldValue.serverTimestamp(),
        'historico': FieldValue.arrayUnion([
          auditEntry(
            'Aviso de retirada confirmado como enviado pelo administrador',
          ),
        ]),
      });

  Future<void> updateFulfillment(
    String id, {
    DateTime? deadline,
    required String instructions,
  }) => firestore
      .collection(StoreEnvironment.collectionName('pedidos'))
      .doc(id)
      .update({
        'previsaoConclusao': deadline == null
            ? null
            : Timestamp.fromDate(deadline),
        'instrucoesEntrega': instructions.trim(),
        'historico': FieldValue.arrayUnion([
          auditEntry('Prazo e instruções atualizados'),
        ]),
      });

  Future<void> confirmRefund(String id) => firestore
      .collection(StoreEnvironment.collectionName('pedidos'))
      .doc(id)
      .update({
        'reembolso': 'Confirmado',
        'dataReembolso': FieldValue.serverTimestamp(),
        'historico': FieldValue.arrayUnion([
          auditEntry('Reembolso confirmado pelo administrador'),
        ]),
      });
}
