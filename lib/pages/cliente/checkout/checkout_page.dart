import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../../shared/theme/tema_site.dart';

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final _formCartaoKey = GlobalKey<FormState>();

  final maskNumeroCartao = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final maskValidade = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final maskCVV = MaskTextInputFormatter(
    mask: '####',
    filter: {"#": RegExp(r'[0-9]')},
  );

  bool _processando = false;

  // Dados do Cliente
  String _nomeCompleto = 'Carregando...';
  String _emailCliente = '';
  String _telefoneCliente = '';
  String _nascimentoCliente = '';
  String _endereco = '';
  String _numeroCasa = '';
  String _bairro = '';
  String _complemento = '';
  String _cidade = '';
  String _uf = '';
  bool _loading = true;

  String _metodoEnvio = 'Retirar na Loja';
  double _valorFrete = 0.0;
  String _metodoPagamento = 'Pix';
  int _parcelas = 1;

  @override
  void initState() {
    super.initState();
    _buscarDadosAutomaticos();
  }

  Future<void> _buscarDadosAutomaticos() async {
    try {
      final user = _auth.currentUser;
      if (user == null) {
        setState(() => _loading = false);
        return;
      }
      final doc = await _firestore.collection('usuarios').doc(user.uid).get();
      if (doc.exists && doc.data() != null) {
        final data = doc.data()!;
        setState(() {
          _nomeCompleto = "${data['nome'] ?? ''} ${data['sobrenome'] ?? ''}"
              .trim();
          _emailCliente = data['email'] ?? 'Não informado';
          _telefoneCliente = data['telefone'] ?? 'Não informado';
          _nascimentoCliente = data['dataNascimento'] ?? 'Não informado';
          _endereco = data['endereco'] ?? 'Rua não informada';
          _numeroCasa = data['numero'] ?? 'S/N';
          _bairro = data['bairro'] ?? 'Não informado';
          _complemento = data['complemento'] ?? '';
          _cidade = data['cidade'] ?? '';
          _uf = data['uf'] ?? '';
          _loading = false;
        });
      }
    } catch (e) {
      setState(() => _loading = false);
    }
  }

  Future<void> _finalizarPedido(CartProvider cart) async {
    if (_processando) return;

    if (_metodoPagamento.contains('Cartão')) {
      if (!_formCartaoKey.currentState!.validate()) return;
    }

    setState(() => _processando = true);

    try {
      final String pedidoId = _firestore.collection('pedidos').doc().id;
      final double totalFinal = cart.total + _valorFrete;

      // 1. Salvar no Firebase
      try {
        final batch = _firestore.batch();
        batch.set(_firestore.collection('pedidos').doc(pedidoId), {
          'pedidoId': pedidoId,
          'clienteId': _auth.currentUser?.uid,
          'nomeCliente': _nomeCompleto,
          'total': totalFinal,
          'itens': cart.items
              .map(
                (i) => {
                  'id': i.product.id,
                  'nome': i.product.name,
                  'preco': i.product.price,
                  'quantidade': i.quantity,
                },
              )
              .toList(),
          'metodoPagamento': _metodoPagamento,
          'metodoEnvio': _metodoEnvio,
          'status': 'Pendente',
          'dataPedido': FieldValue.serverTimestamp(),
        });

        for (var item in cart.items) {
          batch.update(_firestore.collection('produtos').doc(item.product.id), {
            'quantity': FieldValue.increment(-item.quantity),
          });
        }
        await batch.commit();
      } catch (e) {
        debugPrint("Erro banco: $e");
      }

      // 2. WhatsApp
      String mensagem =
          "🛍️ *Novo Pedido - Benta Laços*\n\n"
          "👤 *Cliente:* $_nomeCompleto\n"
          "📞 *Tel:* $_telefoneCliente\n"
          "📍 *Endereço:* $_endereco, $_numeroCasa\n"
          "🏙️ *Cidade:* $_cidade - $_uf\n"
          "🚚 *Frete:* $_metodoEnvio (R\$ ${_valorFrete.toStringAsFixed(2)})\n"
          "💳 *Pagamento:* $_metodoPagamento\n\n"
          "📦 *Produtos:*\n";

      for (var item in cart.items) {
        mensagem +=
            "• ${item.quantity}x ${item.product.name} - R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}\n";
      }
      mensagem += "\n💰 *TOTAL: R\$ ${totalFinal.toStringAsFixed(2)}*";

      final url =
          "https://wa.me/5554999264865?text=${Uri.encodeComponent(mensagem)}";

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);

        // CORREÇÃO AQUI: Alterado de clearCart() para clear()
        cart.clear();

        if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } finally {
      if (mounted) setState(() => _processando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    double totalFinal = cart.total + _valorFrete;

    return Scaffold(
      backgroundColor: const Color(0xFFF8F9FA),
      appBar: AppBar(
        title: const Text(
          "Finalizar Pedido",
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        iconTheme: const IconThemeData(color: Colors.black87),
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: TemaSite.corPrimaria),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSectionTitle("Seus Dados"),
                  _buildBannerClienteOriginal(),
                  const SizedBox(height: 24),

                  _buildSectionTitle("Resumo dos Itens"),
                  _buildItensCarrinho(cart),
                  const SizedBox(height: 24),

                  _buildSectionTitle("1. Como deseja receber?"),
                  _buildOpcaoEnvio('Retirar na Loja', 0.0, Icons.storefront),
                  _buildOpcaoEnvio(
                    'Correios (PAC)',
                    29.90,
                    Icons.local_shipping_outlined,
                  ),
                  _buildOpcaoEnvio('Correios (SEDEX)', 54.90, Icons.speed),
                  const SizedBox(height: 24),

                  _buildSectionTitle("2. Como deseja pagar?"),
                  _buildPagamento('Pix', Icons.pix, Colors.teal),
                  _buildPagamento(
                    'Cartão de Crédito',
                    Icons.credit_card,
                    Colors.pink,
                  ),
                  _buildPagamento(
                    'Cartão de Débito',
                    Icons.credit_card,
                    Colors.blue,
                  ),

                  if (_metodoPagamento.contains('Cartão'))
                    _buildFormCartao(totalFinal),

                  const SizedBox(height: 32),
                  _buildResumoFinanceiro(cart.total, totalFinal),
                  const SizedBox(height: 20),

                  ElevatedButton(
                    onPressed: _processando
                        ? null
                        : () => _finalizarPedido(cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF4CAF50),
                      minimumSize: const Size(double.infinity, 60),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      elevation: 2,
                    ),
                    child: _processando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "ENVIAR PEDIDO PARA WHATSAPP",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                  ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
    );
  }

  Widget _buildSectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12, left: 4),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Colors.black87,
        ),
      ),
    );
  }

  Widget _buildResumoFinanceiro(double subtotal, double total) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(color: Colors.black.withOpacity(0.05), blurRadius: 10),
        ],
      ),
      child: Column(
        children: [
          _resumo("Subtotal Produtos", subtotal),
          const SizedBox(height: 10),
          _resumo("Frete / Entrega", _valorFrete),
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: Divider(),
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text(
                "TOTAL",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              Text(
                "R\$ ${total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: TemaSite.corPrimaria,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBannerClienteOriginal() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          Row(
            children: [
              const CircleAvatar(
                backgroundColor: TemaSite.corPrimaria,
                child: Icon(Icons.person, color: Colors.white),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _nomeCompleto,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    Text(
                      _emailCliente,
                      style: TextStyle(color: Colors.grey[600], fontSize: 13),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const Divider(height: 24),
          _infoRow(
            Icons.location_on_outlined,
            "$_endereco, $_numeroCasa - $_bairro",
            Colors.redAccent,
          ),
          _infoRow(Icons.phone_android, _telefoneCliente, Colors.green),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 4),
    child: Row(
      children: [
        Icon(icon, size: 18, color: color),
        const SizedBox(width: 8),
        Expanded(child: Text(text, style: const TextStyle(fontSize: 13))),
      ],
    ),
  );

  Widget _buildItensCarrinho(CartProvider cart) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: cart.items
            .map(
              (item) => ListTile(
                leading: ClipRRect(
                  borderRadius: BorderRadius.circular(8),
                  child: Image.network(
                    item.product.imageUrl ?? '',
                    width: 45,
                    height: 45,
                    fit: BoxFit.cover,
                    errorBuilder: (_, __, ___) => const Icon(Icons.image),
                  ),
                ),
                title: Text(
                  item.product.name,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                subtitle: Text(
                  "${item.quantity}x R\$ ${item.product.price.toStringAsFixed(2)}",
                ),
                trailing: Text(
                  "R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildPagamento(String t, IconData i, Color c) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    child: RadioListTile(
      title: Text(
        t,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      secondary: Icon(i, color: c),
      value: t,
      activeColor: TemaSite.corPrimaria,
      groupValue: _metodoPagamento,
      onChanged: (val) => setState(() => _metodoPagamento = val!),
    ),
  );

  Widget _buildOpcaoEnvio(String t, double v, IconData icon) => Card(
    margin: const EdgeInsets.only(bottom: 8),
    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    elevation: 0,
    child: RadioListTile(
      title: Text(
        t,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w500),
      ),
      secondary: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 20),
          Text(
            "R\$ ${v.toStringAsFixed(2)}",
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
      value: t,
      activeColor: TemaSite.corPrimaria,
      groupValue: _metodoEnvio,
      onChanged: (val) => setState(() {
        _metodoEnvio = val!;
        _valorFrete = v;
      }),
    ),
  );

  Widget _buildFormCartao(double total) => Container(
    padding: const EdgeInsets.all(16),
    margin: const EdgeInsets.only(top: 10),
    decoration: BoxDecoration(
      color: Colors.white,
      borderRadius: BorderRadius.circular(16),
    ),
    child: Form(
      key: _formCartaoKey,
      child: Column(
        children: [
          if (_metodoPagamento == 'Cartão de Crédito')
            DropdownButtonFormField<int>(
              decoration: const InputDecoration(labelText: "Parcelamento"),
              value: _parcelas,
              items: List.generate(12, (i) => i + 1)
                  .map(
                    (v) => DropdownMenuItem(
                      value: v,
                      child: Text(
                        "${v}x de R\$ ${(total / v).toStringAsFixed(2)}",
                      ),
                    ),
                  )
                  .toList(),
              onChanged: (v) => setState(() => _parcelas = v!),
            ),
          TextFormField(
            decoration: const InputDecoration(
              labelText: "Número do Cartão",
              prefixIcon: Icon(Icons.credit_card),
            ),
            inputFormatters: [maskNumeroCartao],
            validator: (v) => v!.isEmpty ? "Obrigatório" : null,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(
                    labelText: "Validade (MM/AA)",
                  ),
                  inputFormatters: [maskValidade],
                  validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: "CVV"),
                  inputFormatters: [maskCVV],
                  validator: (v) => v!.isEmpty ? "Obrigatório" : null,
                ),
              ),
            ],
          ),
        ],
      ),
    ),
  );

  Widget _resumo(String l, double v) => Row(
    mainAxisAlignment: MainAxisAlignment.spaceBetween,
    children: [
      Text(l, style: const TextStyle(color: Colors.black54)),
      Text(
        "R\$ ${v.toStringAsFixed(2)}",
        style: const TextStyle(fontWeight: FontWeight.w500),
      ),
    ],
  );
}
