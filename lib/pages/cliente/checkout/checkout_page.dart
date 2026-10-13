import 'package:benta_lacos/core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../domain/services/order_service.dart';
import '../../../domain/services/pdf_service_cliente.dart';
import '../../../shared/utils/store_format.dart';
import '../../../shared/theme/tema_site.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});
  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final _form = GlobalKey<FormState>();
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _address = TextEditingController();
  final _cep = TextEditingController();
  final _firestore = StoreEnvironment.database;
  bool _loading = true;
  bool _processing = false;
  String? _loadError;
  String _delivery = 'Entrega a combinar';
  String _payment = 'Pix';
  late final String _orderId;
  Map<String, dynamic>? _saved;
  DateTime? _savedAt;
  @override
  void initState() {
    super.initState();
    _orderId = _firestore
        .collection(StoreEnvironment.collectionName('pedidos'))
        .doc()
        .id;
    _loadProfile();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    _address.dispose();
    _cep.dispose();
    super.dispose();
  }

  Future<void> _loadProfile() async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null)
        throw StateError('Entre na sua conta para registrar o pedido.');
      final snapshot = await _firestore
          .collection(StoreEnvironment.collectionName('usuarios'))
          .doc(user.uid)
          .get();
      final data = snapshot.data() ?? {};
      _name.text = '${data['nome'] ?? ''} ${data['sobrenome'] ?? ''}'.trim();
      _phone.text = data['telefone']?.toString() ?? '';
      _cep.text = data['cep']?.toString() ?? '';
      _address.text = [
        data['rua'] ?? data['endereco'],
        data['numero'],
        data['bairro'],
        data['cidade'],
        data['uf'],
      ].where((s) => s != null && s.toString().isNotEmpty).join(', ');
    } catch (_) {
      _loadError =
          'Não foi possível carregar seus dados. Preencha os campos abaixo.';
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  void _notice(String text) {
    if (mounted)
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(text)));
  }

  Future<void> _save() async {
    if (_processing || _saved != null || !_form.currentState!.validate())
      return;
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      Navigator.pushNamed(context, '/login');
      return;
    }
    final cart = context.read<CartProvider>();
    final items = cart.items
        .where((i) => i.selecionado)
        .map((i) => CartItem(product: i.product, quantity: i.quantity))
        .toList();
    setState(() => _processing = true);
    try {
      final data = await OrderService(_firestore).createRequest(
        id: _orderId,
        uid: user.uid,
        items: items,
        customer: {
          'nome': _name.text.trim(),
          'telefone': _phone.text.trim(),
          'email': user.email ?? '',
          'endereco': _address.text.trim(),
          'cep': _cep.text.trim(),
        },
        delivery: _delivery,
        payment: _payment,
      );
      if (!mounted) return;
      setState(() {
        _saved = data;
        _savedAt = DateTime.now();
      });
      await cart.limparItensComprados();
    } catch (error, stackTrace) {
      debugPrint('Falha ao registrar pedido $_orderId: $error\n$stackTrace');
      _notice(
        error is StateError
            ? error.message
            : 'Não foi possível registrar o pedido agora. Confira sua conexão e tente novamente. Se persistir, entre em contato com a Benta Laços.',
      );
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  String get _message {
    final order = _saved!;
    final customer = order['cliente'] as Map<String, dynamic>;
    final lines = List<Map<String, dynamic>>.from(order['itens']);
    return '${order['pedidoTeste'] == true ? 'PEDIDO DE TESTE — sem compra real.\n\n' : ''}'
        'Olá! Gostaria de confirmar meu pedido #$_orderId na Benta Laços.\n\n'
        'Nome: ${customer['nome']}\nTelefone: ${customer['telefone']}\n'
        'Endereço: ${customer['endereco']}\nCEP: ${customer['cep']}\n'
        'Entrega: ${order['metodoEnvio']}\nPagamento preferido: ${order['metodoPagamento']}\n\n'
        '${lines.map((i) => '${i['quantidade']}x ${i['nome']} — ${formatMoney((i['preco'] as num) * (i['quantidade'] as num))}').join('\n')}\n\n'
        'Subtotal: ${formatMoney(order['subtotal'] as num)}\n'
        '${order['freteACombinar'] == true ? 'Frete e prazo a confirmar pelo atendimento.' : 'Retirada na loja, sem frete.'}\n'
        'Aguardo confirmação da disponibilidade e do valor final antes de pagar.';
  }

  Future<void> _whatsapp() async {
    try {
      final contact = await _firestore
          .collection(StoreEnvironment.collectionName('institucional'))
          .doc('contato')
          .get();
      final phone = whatsappPhone(
        (contact.data()?['whatsapp'] ?? '54999264865').toString(),
      );
      final url = Uri.https('wa.me', '/$phone', {'text': _message});
      if (!await launchUrl(url, mode: LaunchMode.externalApplication))
        throw StateError('Não abriu');
    } catch (_) {
      _notice(
        'Seu pedido está salvo. Copie a mensagem abaixo e envie ao atendimento.',
      );
    }
  }

  Future<void> _pdf() async {
    try {
      final order = _saved!;
      await PdfServiceCliente.gerarComprovantePedido(
        pedidoId: _orderId,
        nomeCliente: (order['cliente'] as Map)['nome'],
        itens: List<Map<String, dynamic>>.from(order['itens']),
        total: (order['total'] as num).toDouble(),
        frete: (order['valorFrete'] as num? ?? 0).toDouble(),
        metodoPagamento:
            '${order['metodoPagamento']} — pendente${order['freteACombinar'] == true ? '; frete a combinar' : ''}',
        enderecoCompleto: order['enderecoExibicao'],
        dataPedido: Timestamp.fromDate(_savedAt!),
        freteACombinar: order['freteACombinar'] == true,
        status: order['pedidoTeste'] == true ? 'Teste — Pendente' : 'Pendente',
      );
    } catch (_) {
      _notice(
        'Pedido salvo. Não foi possível gerar o resumo agora; tente novamente.',
      );
    }
  }

  Widget _field(
    String label,
    TextEditingController controller, {
    bool required = true,
    TextInputType? keyboard,
    String? Function(String?)? validator,
  }) => Padding(
    padding: const EdgeInsets.only(bottom: 16),
    child: TextFormField(
      controller: controller,
      keyboardType: keyboard,
      decoration: InputDecoration(labelText: label),
      validator:
          validator ??
          (v) => required && (v == null || v.trim().isEmpty)
              ? 'Preencha este campo'
              : null,
    ),
  );
  Widget _success() => Column(
    crossAxisAlignment: CrossAxisAlignment.stretch,
    children: [
      const Icon(
        Icons.check_circle_outline,
        color: TemaSite.corPrimaria,
        size: 64,
      ),
      const SizedBox(height: 20),
      Text(
        _saved?['pedidoTeste'] == true
            ? 'Pedido de teste registrado!'
            : 'Pedido registrado!',
        textAlign: TextAlign.center,
        style: const TextStyle(fontSize: 28, fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 12),
      SelectableText('Pedido #$_orderId', textAlign: TextAlign.center),
      const SizedBox(height: 20),
      const Text(
        'Continue pelo WhatsApp para confirmar disponibilidade, entrega e pagamento. Seu pedido está pendente e ainda não reserva estoque.',
        textAlign: TextAlign.center,
      ),
      const SizedBox(height: 24),
      ElevatedButton.icon(
        onPressed: _whatsapp,
        icon: const Icon(Icons.chat_outlined),
        label: const Text('Continuar pelo WhatsApp'),
      ),
      TextButton.icon(
        onPressed: () async {
          await Clipboard.setData(ClipboardData(text: _message));
          _notice('Mensagem copiada');
        },
        icon: const Icon(Icons.copy),
        label: const Text('Copiar mensagem do pedido'),
      ),
      TextButton.icon(
        onPressed: _pdf,
        icon: const Icon(Icons.download_outlined),
        label: const Text('Baixar resumo do pedido'),
      ),
      TextButton(
        onPressed: () => Navigator.pushNamedAndRemoveUntil(
          context,
          '/meus-pedidos',
          (r) => r.isFirst,
        ),
        child: const Text('Acompanhar meus pedidos'),
      ),
    ],
  );
  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final selected = cart.items.where((i) => i.selecionado).toList();
    final subtotal = selected.fold(
      0.0,
      (sum, i) => sum + i.product.price * i.quantity,
    );
    return Scaffold(
      appBar: AppBar(title: const Text('Revisar pedido')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 760),
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: _saved != null
                        ? _success()
                        : Form(
                            key: _form,
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.stretch,
                              children: [
                                const Text(
                                  'Vamos cuidar de cada detalhe',
                                  style: TextStyle(
                                    fontSize: 26,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Você registra o pedido aqui e conclui com nosso atendimento no WhatsApp. O pagamento será combinado após a confirmação.',
                                ),
                                const SizedBox(height: 24),
                                if (_loadError != null)
                                  Padding(
                                    padding: const EdgeInsets.only(bottom: 16),
                                    child: Text(_loadError!),
                                  ),
                                _field('Nome completo', _name),
                                _field(
                                  'Telefone com DDD',
                                  _phone,
                                  keyboard: TextInputType.phone,
                                  validator: (v) =>
                                      (v ?? '')
                                              .replaceAll(RegExp(r'\D'), '')
                                              .length <
                                          10
                                      ? 'Informe um telefone com DDD'
                                      : null,
                                ),
                                DropdownButtonFormField<String>(
                                  value: _delivery,
                                  decoration: const InputDecoration(
                                    labelText: 'Como deseja receber?',
                                  ),
                                  items:
                                      ['Entrega a combinar', 'Retirar na loja']
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) =>
                                      setState(() => _delivery = v!),
                                ),
                                const SizedBox(height: 16),
                                if (_delivery != 'Retirar na loja') ...[
                                  _field(
                                    'CEP de entrega',
                                    _cep,
                                    keyboard: TextInputType.number,
                                    validator: (v) =>
                                        (v ?? '')
                                                .replaceAll(RegExp(r'\D'), '')
                                                .length !=
                                            8
                                        ? 'Informe um CEP com 8 dígitos'
                                        : null,
                                  ),
                                  _field(
                                    'Endereço completo, número, bairro e cidade/UF',
                                    _address,
                                  ),
                                  const Text(
                                    'Frete e prazo serão informados pelo atendimento para este CEP, antes do pagamento.',
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                DropdownButtonFormField<String>(
                                  value: _payment,
                                  decoration: const InputDecoration(
                                    labelText: 'Preferência de pagamento',
                                  ),
                                  items:
                                      ['Pix', 'Cartão — consultar atendimento']
                                          .map(
                                            (s) => DropdownMenuItem(
                                              value: s,
                                              child: Text(s),
                                            ),
                                          )
                                          .toList(),
                                  onChanged: (v) =>
                                      setState(() => _payment = v!),
                                ),
                                const SizedBox(height: 24),
                                const Text(
                                  'Produtos selecionados',
                                  style: TextStyle(
                                    fontSize: 20,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                ...selected.map(
                                  (i) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    title: Text(i.product.name),
                                    subtitle: Text(
                                      '${i.quantity} × ${formatMoney(i.product.price)}',
                                    ),
                                    trailing: Text(
                                      formatMoney(i.quantity * i.product.price),
                                    ),
                                  ),
                                ),
                                const Divider(),
                                Text(
                                  'Subtotal: ${formatMoney(subtotal)}',
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.bold,
                                    color: TemaSite.corPrimaria,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  _delivery == 'Retirar na loja'
                                      ? 'Retirada sem frete. Combine o local e o horário com o atendimento.'
                                      : 'Frete a combinar. O subtotal acima não inclui entrega.',
                                ),
                                const SizedBox(height: 24),
                                ElevatedButton(
                                  onPressed: _processing || selected.isEmpty
                                      ? null
                                      : _save,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.all(18),
                                  ),
                                  child: _processing
                                      ? const SizedBox(
                                          width: 24,
                                          height: 24,
                                          child: CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2,
                                          ),
                                        )
                                      : const Text('Registrar pedido'),
                                ),
                                const SizedBox(height: 12),
                                const Text(
                                  'Disponibilidade e preços são conferidos ao registrar. Nenhuma cobrança é feita nesta etapa.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                  ),
                ),
              ),
            ),
    );
  }
}
