import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/services/order_service.dart';
import '../../../domain/services/admin_metrics.dart';
import '../../../shared/utils/store_format.dart';
import '../login/admin_page.dart';
import '../widgets/admin_ui.dart';
import 'admin_order_list.dart';
import '../widgets/admin_actions.dart';
import '../../../domain/services/order_policy.dart';
import 'order_status_dialog.dart';
import '../../../domain/services/order_messages.dart';

class GestaoPedidosPage extends StatefulWidget {
  final bool embedded;
  final String initialStatus;
  const GestaoPedidosPage({
    super.key,
    this.embedded = false,
    this.initialStatus = 'Todos',
  });
  @override
  State<GestaoPedidosPage> createState() => _GestaoPedidosPageState();
}

class _GestaoPedidosPageState extends State<GestaoPedidosPage> {
  late Stream<QuerySnapshot<Map<String, dynamic>>> _stream;
  String _search = '', _status = 'Todos';
  bool _archived = false;
  DateTimeRange? _range;
  int _page = 0;
  final _cursors = <DocumentSnapshot<Map<String, dynamic>>?>[null];
  @override
  void initState() {
    super.initState();
    _status = widget.initialStatus;
    _reload();
  }

  void _reload({bool reset = true}) {
    if (reset) {
      _page = 0;
      _cursors.clear();
      _cursors.add(null);
    }
    Query<Map<String, dynamic>> query = StoreEnvironment.database.collection(
      'pedidos',
    );
    if (_status != 'Todos') query = query.where('status', isEqualTo: _status);
    if (_status != 'Cancelado')
      query = query.where('arquivado', isEqualTo: _archived);
    if (_search.trim().isNotEmpty)
      query = query.where(
        'buscaTokens',
        arrayContains: normalizeSearch(_search),
      );
    if (_range != null) {
      query = query
          .where(
            'dataPedido',
            isGreaterThanOrEqualTo: Timestamp.fromDate(_range!.start),
          )
          .where(
            'dataPedido',
            isLessThan: Timestamp.fromDate(
              _range!.end.add(const Duration(days: 1)),
            ),
          );
    }
    query = query.orderBy('dataPedido', descending: true);
    if (_cursors[_page] != null)
      query = query.startAfterDocument(_cursors[_page]!);
    _stream = query.limit(21).snapshots();
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.embedded) return const AdminPage(initialSection: 1);
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const AdminHeading(
          'Pedidos',
          'Acompanhe o atendimento, confirme os pagamentos e registre os envios.',
        ),
        Wrap(
          spacing: 16,
          runSpacing: 12,
          crossAxisAlignment: WrapCrossAlignment.center,
          children: [
            SizedBox(
              width: 280,
              child: TextField(
                decoration: const InputDecoration(
                  labelText: 'Buscar cliente ou pedido',
                  prefixIcon: Icon(Icons.search),
                ),
                onChanged: (v) => setState(() {
                  _search = v;
                  _reload();
                }),
              ),
            ),
            SizedBox(
              width: 180,
              child: DropdownButtonFormField<String>(
                key: ValueKey(_status),
                initialValue: _status,
                decoration: const InputDecoration(labelText: 'Status'),
                items:
                    [
                          'Todos',
                          'Pendente',
                          'Aceito',
                          'Fabricado',
                          'Pago',
                          'Enviado',
                          'Entregue',
                          'Cancelado',
                        ]
                        .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                        .toList(),
                onChanged: (v) => setState(() {
                  _status = v!;
                  _reload();
                }),
              ),
            ),
            OutlinedButton.icon(
              onPressed: () async {
                final r = await showDateRangePicker(
                  context: context,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                  initialDateRange: _range,
                );
                if (r != null && mounted)
                  setState(() {
                    _range = r;
                    _reload();
                  });
              },
              icon: const Icon(Icons.date_range),
              label: Text(
                _range == null
                    ? 'Filtrar período'
                    : '${DateFormat('dd/MM').format(_range!.start)} a ${DateFormat('dd/MM').format(_range!.end)}',
              ),
            ),
            if (_range != null)
              TextButton(
                onPressed: () => setState(() {
                  _range = null;
                  _reload();
                }),
                child: const Text('Todo o período'),
              ),
            FilterChip(
              label: const Text('Cancelados'),
              selected: _status == 'Cancelado',
              onSelected: (v) => setState(() {
                _status = v ? 'Cancelado' : 'Todos';
                _archived = false;
                _reload();
              }),
            ),
            FilterChip(
              label: const Text('Arquivados'),
              selected: _archived,
              onSelected: (v) => setState(() {
                _archived = v;
                _reload();
              }),
            ),
          ],
        ),
        const SizedBox(height: 24),
        StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
          stream: _stream,
          builder: (context, s) {
            if (s.hasError)
              return AdminEmpty(
                'Não foi possível carregar os pedidos.',
                retry: () => setState(_reload),
              );
            if (!s.hasData)
              return const Center(child: CircularProgressIndicator());
            final orders =
                s.data!.docs.where((d) {
                  final o = d.data();
                  final archive =
                      o['arquivado'] == true || o['status'] == 'Excluido';
                  return (_status == 'Cancelado' || archive == _archived) &&
                      (_status == 'Todos' || o['status'] == _status) &&
                      inDateRange(o, _range?.start, _range?.end);
                }).toList()..sort(
                  (a, b) =>
                      (recordDate(b.data()['dataPedido']) ?? DateTime(1970))
                          .compareTo(
                            recordDate(a.data()['dataPedido']) ??
                                DateTime(1970),
                          ),
                );
            if (orders.isEmpty)
              return AdminEmpty(
                'Nenhum pedido encontrado para os filtros selecionados.',
                retry: _page > 0 ? () => setState(() => _reload()) : null,
              );
            final page = _page;
            final hasNext = s.data!.docs.length > 20;
            return Column(
              children: [
                AdminOrderList(
                  orders: orders
                      .take(20)
                      .map((d) => {...d.data(), 'pedidoId': d.id})
                      .toList(),
                  onOpen: (id) => openOrderDetails(context, id),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton(
                      onPressed: page > 0
                          ? () => setState(() {
                              _page = page - 1;
                              _reload(reset: false);
                            })
                          : null,
                      icon: const Icon(Icons.chevron_left),
                    ),
                    Text('Página ${page + 1} • até 20 pedidos'),
                    IconButton(
                      onPressed: hasNext
                          ? () => setState(() {
                              final cursor = s.data!.docs[19];
                              if (_cursors.length <= page + 1) {
                                _cursors.add(cursor);
                              } else {
                                _cursors[page + 1] = cursor;
                              }
                              _page = page + 1;
                              _reload(reset: false);
                            })
                          : null,
                      icon: const Icon(Icons.chevron_right),
                    ),
                  ],
                ),
              ],
            );
          },
        ),
      ],
    );
  }
}

String orderNextAction(Map<String, dynamic> o) => switch (o['status']) {
  'Pendente' => 'Próxima ação: aceitar pedido',
  'Aceito' => 'Próxima ação: concluir fabricação',
  'Fabricado' =>
    o['metodoEnvio'] == 'Retirar na loja'
        ? 'Próxima ação: avisar cliente para retirar'
        : 'Próxima ação: registrar envio',
  'Pago' => 'Próxima ação: registrar envio',
  'Enviado' => 'Próxima ação: confirmar entrega',
  _ => 'Atendimento finalizado',
};
Future<void> openOrderDetails(BuildContext context, String id) =>
    showDialog<void>(
      useRootNavigator: false,
      context: context,
      barrierDismissible: false,
      builder: (_) => OrderDetails(id: id),
    );

class OrderDetails extends StatefulWidget {
  final String id;
  const OrderDetails({super.key, required this.id});
  @override
  State<OrderDetails> createState() => _OrderDetailsState();
}

class _OrderDetailsState extends State<OrderDetails> {
  final _service = OrderService(StoreEnvironment.database);
  bool _busy = false;
  String? _error;
  Future<void> _run(Future<void> Function() action, String message) async {
    setState(() {
      _busy = true;
      _error = null;
    });
    try {
      await action();
      if (mounted) adminMessage(context, message);
    } catch (e) {
      debugPrint('Falha administrativa no pedido ${widget.id}: $e');
      if (mounted)
        setState(
          () => _error = e is StateError
              ? e.message
              : 'Não foi possível salvar agora. Confira sua conexão e tente novamente.',
        );
    } finally {
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _freight() async {
    final input = TextEditingController();
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Informar frete combinado'),
        content: Form(
          key: key,
          child: TextFormField(
            controller: input,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: const InputDecoration(
              labelText: 'Valor do frete em R\$',
            ),
            validator: (v) {
              final n = double.tryParse((v ?? '').replaceAll(',', '.'));
              return n == null || !n.isFinite || n < 0
                  ? 'Informe um valor válido.'
                  : null;
            },
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (ok == true)
      await _run(
        () => _service.quoteShipping(
          widget.id,
          double.parse(input.text.replaceAll(',', '.')),
        ),
        'Frete atualizado.',
      );
    input.dispose();
  }

  Future<void> _pay() async {
    String? method;
    final key = GlobalKey<FormState>();
    final ok = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Confirmar pagamento recebido'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Confirme apenas após verificar o recebimento. O estoque será atualizado.',
              ),
              const SizedBox(height: 16),
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(
                  labelText: 'Meio de pagamento recebido',
                ),
                items: ['Pix', 'Crédito', 'Débito', 'Dinheiro', 'Outro']
                    .map((v) => DropdownMenuItem(value: v, child: Text(v)))
                    .toList(),
                onChanged: (v) => method = v,
                validator: (v) =>
                    v == null ? 'Selecione o pagamento recebido.' : null,
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Confirmar recebimento'),
          ),
        ],
      ),
    );
    if (ok == true)
      await _run(
        () => _service.changeStatus(
          widget.id,
          'Pago',
          paymentMethod: method,
          preserveProductionStatus: true,
        ),
        'Pagamento confirmado.',
      );
  }

  Future<void> _alterStatus(Map<String, dynamic> order) async {
    final next = await showDialog<String>(
      useRootNavigator: false,
      context: context,
      builder: (_) => OrderStatusDialog(order: order),
    );
    if (next == null || !mounted) return;
    if (next == 'Cancelado') {
      await _cancelOrder();
      return;
    }
    if (next == 'Pago') {
      await _pay();
    } else if (next == 'Enviado') {
      await _send();
    } else {
      final explanation = next == 'Cancelado'
          ? order['pedidoTeste'] == true
                ? 'O pedido de teste será cancelado, sem movimentar estoque.'
                : 'A baixa de estoque deste fluxo será revertida. Confirme separadamente eventual reembolso ao cliente.'
          : switch (next) {
              'Aceito' =>
                'O cliente verá que o pedido foi aceito e está em fabricação.',
              'Fabricado' =>
                order['metodoEnvio'] == 'Retirar na loja'
                    ? 'O cliente verá que o pedido está pronto para retirar. O aviso de WhatsApp ficará disponível.'
                    : 'O cliente verá que o pedido foi fabricado e está pronto para envio.',
              _ => 'O pedido será marcado como entregue.',
            };
      if (await adminConfirm(context, 'Marcar como $next?', explanation)) {
        await _run(
          () => _service.changeStatus(widget.id, next),
          'Status atualizado para $next.',
        );
        if (_error == null &&
            next == 'Fabricado' &&
            order['metodoEnvio'] == 'Retirar na loja' &&
            mounted) {
          await _pickupNotice({...order, 'status': 'Fabricado'});
        }
      }
    }
  }

  Future<void> _pickupNotice(Map<String, dynamic> order) async {
    final customer = order['cliente'] is Map ? order['cliente'] as Map : {};
    final phone = whatsappPhone('${customer['telefone'] ?? ''}');
    final message = pickupReadyMessage(widget.id, order);
    await showDialog<void>(
      context: context,
      useRootNavigator: false,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Avisar que está pronto para retirar'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              SelectableText(message),
              const SizedBox(height: 16),
              const Text(
                'Abra o WhatsApp e toque em Enviar. Abrir o aviso não confirma o envio.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () async {
              if (!await adminConfirm(
                context,
                'Confirmar aviso enviado?',
                'Confirme somente depois de tocar em Enviar no WhatsApp.',
              ))
                return;
              await _run(
                () => _service.markPickupNoticeSent(widget.id),
                'Envio do aviso registrado.',
              );
              if (dialogContext.mounted && _error == null)
                Navigator.pop(dialogContext);
            },
            child: const Text('Já enviei a mensagem'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('Voltar'),
          ),
          TextButton(
            onPressed: () async {
              await Clipboard.setData(ClipboardData(text: message));
              if (mounted) adminMessage(context, 'Mensagem copiada.');
            },
            child: const Text('Copiar mensagem'),
          ),
          FilledButton(
            onPressed: () async {
              if (!RegExp(r'^55\d{10,11}$').hasMatch(phone)) {
                adminMessage(
                  context,
                  'Confira o telefone do cliente antes de enviar.',
                );
                return;
              }
              try {
                final opened = await launchUrl(
                  Uri.https('wa.me', '/$phone', {'text': message}),
                  mode: LaunchMode.externalApplication,
                );
                if (!opened && mounted)
                  adminMessage(
                    context,
                    'Não foi possível abrir o WhatsApp. Copie a mensagem e envie ao cliente.',
                  );
              } catch (_) {
                if (mounted)
                  adminMessage(
                    context,
                    'Não foi possível abrir o WhatsApp. Copie a mensagem e envie ao cliente.',
                  );
              }
            },
            child: const Text('Abrir WhatsApp do cliente'),
          ),
        ],
      ),
    );
  }

  Future<void> _cancelOrder() async {
    final reason = TextEditingController();
    final key = GlobalKey<FormState>();
    String? requester;
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (c) => AlertDialog(
        title: const Text('Cancelar pedido'),
        content: Form(
          key: key,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              DropdownButtonFormField<String>(
                initialValue: requester,
                decoration: const InputDecoration(labelText: 'Quem solicitou?'),
                validator: (v) =>
                    v == null ? 'Informe quem solicitou o cancelamento' : null,
                items: ['Cliente', 'Loja']
                    .map((s) => DropdownMenuItem(value: s, child: Text(s)))
                    .toList(),
                onChanged: (v) => requester = v!,
              ),
              TextFormField(
                controller: reason,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Motivo do cancelamento',
                ),
                validator: (v) =>
                    (v ?? '').trim().isEmpty ? 'Informe o motivo' : null,
              ),
              const Text(
                'Eventual reembolso deve ser realizado e confirmado separadamente.',
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () {
              if (key.currentState!.validate()) Navigator.pop(c, true);
            },
            child: const Text('Confirmar cancelamento'),
          ),
        ],
      ),
    );
    if (ok == true)
      await _run(
        () => _service.changeStatus(
          widget.id,
          'Cancelado',
          cancellationReason: reason.text,
          requestedBy: requester,
        ),
        'Pedido cancelado e motivo registrado.',
      );
    reason.dispose();
  }

  Future<void> _fulfillment(Map<String, dynamic> order) async {
    final instructions = TextEditingController(
      text: '${order['instrucoesEntrega'] ?? ''}',
    );
    DateTime? deadline = recordDate(order['previsaoConclusao']);
    final ok = await showDialog<bool>(
      context: context,
      useRootNavigator: false,
      builder: (c) => StatefulBuilder(
        builder: (c, update) => AlertDialog(
          title: const Text('Prazo e instruções para o cliente'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextButton(
                onPressed: () async {
                  final date = await showDatePicker(
                    context: c,
                    initialDate: deadline ?? DateTime.now(),
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2100),
                  );
                  if (date != null) update(() => deadline = date);
                },
                child: Text(
                  deadline == null
                      ? 'Definir previsão de conclusão'
                      : DateFormat('dd/MM/yyyy').format(deadline!),
                ),
              ),
              TextButton(
                onPressed: () => update(() => deadline = null),
                child: const Text('Sem previsão definida'),
              ),
              TextField(
                controller: instructions,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: 'Local, horário e orientações de entrega/retirada',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(c, false),
              child: const Text('Voltar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(c, true),
              child: const Text('Salvar'),
            ),
          ],
        ),
      ),
    );
    if (ok == true)
      await _run(
        () => _service.updateFulfillment(
          widget.id,
          deadline: deadline,
          instructions: instructions.text,
        ),
        'Prazo e instruções atualizados para o cliente.',
      );
    instructions.dispose();
  }

  Future<void> _send() async {
    final code = TextEditingController();
    final ok = await showDialog<bool>(
      useRootNavigator: false,
      context: context,
      builder: (c) => AlertDialog(
        title: const Text('Registrar envio ou retirada'),
        content: TextField(
          controller: code,
          decoration: const InputDecoration(
            labelText: 'Código de rastreio (se aplicável)',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(c, false),
            child: const Text('Voltar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(c, true),
            child: const Text('Registrar'),
          ),
        ],
      ),
    );
    if (ok == true)
      await _run(
        () => _service.changeStatus(
          widget.id,
          'Enviado',
          trackingCode: code.text,
        ),
        'Envio registrado.',
      );
    code.dispose();
  }

  @override
  Widget build(BuildContext context) => PopScope(
    canPop: !_busy,
    child: Dialog(
      child: ConstrainedBox(
        constraints: BoxConstraints(
          maxWidth: 820,
          maxHeight: MediaQuery.sizeOf(context).height - 48,
        ),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            children: [
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Detalhes do pedido',
                      style: TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _busy ? null : () => Navigator.pop(context),
                    icon: const Icon(Icons.close),
                  ),
                ],
              ),
              if (_busy) const LinearProgressIndicator(),
              if (_error != null)
                Padding(
                  padding: const EdgeInsets.all(12),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              Expanded(
                child: StreamBuilder<DocumentSnapshot<Map<String, dynamic>>>(
                  stream: StoreEnvironment.database
                      .collection(StoreEnvironment.collectionName('pedidos'))
                      .doc(widget.id)
                      .snapshots(),
                  builder: (context, s) {
                    if (s.hasError)
                      return const AdminEmpty(
                        'Não foi possível carregar o pedido. Feche e tente novamente.',
                      );
                    if (!s.hasData)
                      return const Center(child: CircularProgressIndicator());
                    final o = s.data!.data();
                    if (o == null)
                      return const AdminEmpty('Pedido não encontrado.');
                    final client = o['cliente'] is Map
                        ? Map<String, dynamic>.from(o['cliente'])
                        : <String, dynamic>{};
                    final status = '${o['status'] ?? 'Pendente'}';
                    final archived = o['arquivado'] == true;
                    return SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          SelectableText('Pedido ${widget.id}'),
                          if (o['pedidoTeste'] == true)
                            const Text(
                              'Pedido de teste — sem movimentação de estoque.',
                            ),
                          const SizedBox(height: 12),
                          AdminStatus(status),
                          Text(
                            'Pagamento: ${o['pagamentoConfirmado'] ?? 'Aguardando confirmação'}',
                          ),
                          if (recordDate(o['previsaoConclusao']) != null)
                            Text(
                              'Previsão: ${DateFormat('dd/MM/yyyy').format(recordDate(o['previsaoConclusao'])!)}',
                            ),
                          if (o['instrucoesEntrega'] != null)
                            Text('${o['instrucoesEntrega']}'),
                          if (o['avisoRetirada'] is Map)
                            Text(
                              'Aviso de retirada: ${o['avisoRetirada']['status'] == 'enviado_manual' ? 'Envio confirmado pelo administrador' : 'Aguardando envio'}',
                            ),
                          if (status == 'Cancelado') ...[
                            const SizedBox(height: 12),
                            Text(cancellationSummary(o)),
                            Text(
                              'Motivo: ${o['cancelamento']?['detalhes']?['motivo'] ?? 'Não registrado'}',
                            ),
                            Text(
                              'Solicitado por: ${o['cancelamento']?['detalhes']?['solicitadoPor'] ?? 'Não registrado'}',
                            ),
                            if (o['reembolso'] != null)
                              Text('Reembolso: ${o['reembolso']}'),
                            if (o['reembolso'] == 'A verificar')
                              TextButton(
                                onPressed: _busy
                                    ? null
                                    : () async {
                                        if (await adminConfirm(
                                          context,
                                          'Confirmar reembolso?',
                                          'Confirme somente após devolver o valor ao cliente.',
                                        ))
                                          await _run(
                                            () => _service.confirmRefund(
                                              widget.id,
                                            ),
                                            'Reembolso registrado.',
                                          );
                                      },
                                child: const Text(
                                  'Confirmar reembolso realizado',
                                ),
                              ),
                          ],
                          if (allowedOrderStatuses(
                            status,
                            pickup: o['metodoEnvio'] == 'Retirar na loja',
                          ).isNotEmpty) ...[
                            const SizedBox(height: 12),
                            OutlinedButton.icon(
                              onPressed: _busy ? null : () => _alterStatus(o),
                              icon: const Icon(Icons.edit_outlined),
                              label: const Text('Alterar status'),
                            ),
                          ],
                          const SizedBox(height: 16),
                          Text(
                            '${o['nomeCliente'] ?? client['nome'] ?? 'Cliente'}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          ...client.entries.map(
                            (e) => Padding(
                              padding: const EdgeInsets.only(top: 6),
                              child: SelectableText('${e.key}: ${e.value}'),
                            ),
                          ),
                          if (client.isEmpty)
                            SelectableText(
                              '${o['enderecoExibicao'] ?? 'Contato não registrado neste pedido.'}',
                            ),
                          TextButton.icon(
                            onPressed: () async {
                              await Clipboard.setData(
                                ClipboardData(
                                  text: client.entries
                                      .map((e) => '${e.key}: ${e.value}')
                                      .join('\n'),
                                ),
                              );
                              if (context.mounted)
                                adminMessage(
                                  context,
                                  'Dados do cliente copiados.',
                                );
                            },
                            icon: const Icon(Icons.copy),
                            label: const Text('Copiar contato e endereço'),
                          ),
                          if (RegExp(r'^55\d{10,11}$').hasMatch(
                            whatsappPhone('${client['telefone'] ?? ''}'),
                          ))
                            TextButton.icon(
                              icon: const Icon(Icons.chat_outlined),
                              label: const Text('Atender pelo WhatsApp'),
                              onPressed: () async {
                                final uri = Uri.https(
                                  'wa.me',
                                  '/${whatsappPhone('${client['telefone']}')}',
                                  {
                                    'text':
                                        'Olá! Estou entrando em contato sobre seu pedido ${widget.id} na Benta Laços.',
                                  },
                                );
                                try {
                                  if (!await launchUrl(
                                    uri,
                                    mode: LaunchMode.externalApplication,
                                  ))
                                    throw StateError('WhatsApp indisponível.');
                                } catch (_) {
                                  if (context.mounted)
                                    adminMessage(
                                      context,
                                      'Não foi possível abrir o WhatsApp. Copie o contato e tente pelo aplicativo.',
                                    );
                                }
                              },
                            ),
                          const Divider(height: 32),
                          const Text(
                            'Itens do pedido',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          ...(o['itens'] as List? ?? []).whereType<Map>().map(
                            (item) => ListTile(
                              contentPadding: EdgeInsets.zero,
                              title: Text('${item['nome'] ?? 'Produto'}'),
                              subtitle: Text(
                                '${item['quantidade'] ?? 0} unidades × ${formatMoney((item['preco'] as num? ?? 0).toDouble())}',
                              ),
                            ),
                          ),
                          Text(
                            'Entrega: ${o['metodoEnvio'] ?? 'Não informado'}',
                          ),
                          Text(
                            'Frete: ${o['freteACombinar'] == true ? 'A combinar' : formatMoney((o['valorFrete'] as num? ?? 0).toDouble())}',
                          ),
                          Text(
                            'Total: ${formatMoney((o['total'] as num? ?? 0).toDouble())}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          const SizedBox(height: 12),
                          Text(
                            'Preferência de pagamento: ${o['metodoPagamento'] ?? 'Não informada'}',
                          ),
                          Text(
                            'Pagamento recebido: ${o['pagamentoConfirmado'] ?? (isConfirmedOrder(o) ? 'Consulte o registro legado: ${o['metodoPagamento'] ?? 'não informado'}' : 'Ainda não confirmado')}',
                          ),
                          if ('${o['codigoRastreio'] ?? ''}'.isNotEmpty)
                            SelectableText('Rastreio: ${o['codigoRastreio']}'),
                          const SizedBox(height: 24),
                          Wrap(
                            spacing: 12,
                            runSpacing: 12,
                            children: [
                              OutlinedButton(
                                onPressed: _busy ? null : () => _fulfillment(o),
                                child: const Text('Prazo e instruções'),
                              ),
                              if ([
                                    'Pendente',
                                    'Aceito',
                                    'Fabricado',
                                  ].contains(status) &&
                                  o['pagamentoConfirmado'] == null &&
                                  o['pagamentoLegado'] != true)
                                OutlinedButton(
                                  onPressed: _busy ? null : _freight,
                                  child: const Text('Informar frete'),
                                ),
                              if ([
                                    'Pendente',
                                    'Aceito',
                                    'Fabricado',
                                  ].contains(status) &&
                                  o['pagamentoConfirmado'] == null &&
                                  o['pagamentoLegado'] != true &&
                                  o['metodoEnvio'] != 'Retirar na loja')
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _run(
                                          () => _service.setStorePickup(
                                            widget.id,
                                          ),
                                          'Retirada na loja definida. Frete: R\$ 0,00.',
                                        ),
                                  icon: const Icon(Icons.storefront_outlined),
                                  label: const Text('Retirar na loja'),
                                ),
                              if ([
                                    'Pendente',
                                    'Aceito',
                                    'Fabricado',
                                    'Enviado',
                                    'Entregue',
                                  ].contains(status) &&
                                  o['pagamentoConfirmado'] == null &&
                                  o['pagamentoLegado'] != true &&
                                  o['freteACombinar'] != true)
                                FilledButton(
                                  onPressed: _busy ? null : _pay,
                                  child: const Text('Confirmar pagamento'),
                                ),
                              if (readyForPickup(o))
                                FilledButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () => _pickupNotice(o),
                                  icon: const Icon(Icons.message_outlined),
                                  label: const Text(
                                    'Avisar cliente: pronto para retirar',
                                  ),
                                ),
                              if (status == 'Pago' ||
                                  (status == 'Fabricado' && !readyForPickup(o)))
                                FilledButton(
                                  onPressed: _busy ? null : _send,
                                  child: const Text('Registrar envio'),
                                ),
                              if (status == 'Enviado')
                                FilledButton(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          if (await adminConfirm(
                                            context,
                                            'Confirmar entrega?',
                                            'O pedido será marcado como entregue.',
                                          ))
                                            await _run(
                                              () => _service.changeStatus(
                                                widget.id,
                                                'Entregue',
                                              ),
                                              'Entrega confirmada.',
                                            );
                                        },
                                  child: const Text('Confirmar entrega'),
                                ),
                              if (![
                                'Cancelado',
                                'Excluido',
                                'Entregue',
                              ].contains(status))
                                OutlinedButton(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          if (await adminConfirm(
                                            context,
                                            'Cancelar pedido?',
                                            'A baixa de estoque deste fluxo será revertida. Confirme separadamente eventual reembolso ao cliente.',
                                          ))
                                            await _run(
                                              () => _service.changeStatus(
                                                widget.id,
                                                'Cancelado',
                                              ),
                                              'Pedido cancelado.',
                                            );
                                        },
                                  child: const Text('Cancelar pedido'),
                                ),
                              if (status != 'Excluido')
                                OutlinedButton.icon(
                                  onPressed: _busy
                                      ? null
                                      : () async {
                                          if (await adminConfirm(
                                            context,
                                            archived
                                                ? 'Restaurar pedido?'
                                                : 'Arquivar pedido?',
                                            'O status, os valores e o estoque serão preservados.',
                                          ))
                                            await _run(
                                              () => _service.setArchived(
                                                widget.id,
                                                !archived,
                                              ),
                                              archived
                                                  ? 'Pedido restaurado.'
                                                  : 'Pedido arquivado.',
                                            );
                                        },
                                  icon: Icon(
                                    archived
                                        ? Icons.unarchive_outlined
                                        : Icons.archive_outlined,
                                  ),
                                  label: Text(
                                    archived ? 'Restaurar' : 'Arquivar',
                                  ),
                                ),
                            ],
                          ),
                          const Divider(height: 40),
                          const Text(
                            'Histórico de alterações',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                            ),
                          ),
                          AdminHistory(o['historico'] as List? ?? []),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
