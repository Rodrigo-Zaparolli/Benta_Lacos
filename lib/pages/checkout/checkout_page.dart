import 'package:benta_lacos/models/providers/cart_provider.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../../tema/tema_site.dart';

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

  // Controle de Processamento para não duplicar
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

  // Função centralizada para processar e enviar
  Future<void> _finalizarPedido(CartProvider cart) async {
    if (_processando) return; // Se já estiver processando, ignora novos cliques

    if (_metodoPagamento.contains('Cartão')) {
      if (!_formCartaoKey.currentState!.validate()) return;
    }

    setState(() => _processando = true);

    try {
      // 1. Tentar salvar no Firebase e baixar estoque em segundo plano
      final String pedidoId = _firestore.collection('pedidos').doc().id;
      final double totalFinal = cart.total + _valorFrete;

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
          'dataPedido': FieldValue.serverTimestamp(),
        });

        for (var item in cart.items) {
          batch.update(_firestore.collection('produtos').doc(item.product.id), {
            'quantity': FieldValue.increment(-item.quantity),
          });
        }
        await batch.commit();
      } catch (e) {
        debugPrint(
          "Erro ao salvar no banco, mas prosseguindo para o WhatsApp: $e",
        );
      }

      // 2. Preparar e enviar mensagem detalhada do WhatsApp
      String mensagem =
          "🛍️ *Novo Pedido - Benta Laços*\n\n"
          "👤 *Cliente:* $_nomeCompleto\n"
          "📧 *E-mail:* $_emailCliente\n"
          "📞 *Tel:* $_telefoneCliente\n"
          "🎂 *Nasc:* $_nascimentoCliente\n"
          "📍 *Endereço:* $_endereco, $_numeroCasa\n"
          "🏡 *Bairro:* $_bairro\n";

      if (_complemento.isNotEmpty) mensagem += "🏢 *Comp:* $_complemento\n";
      mensagem +=
          "🏙️ *Cidade:* $_cidade - $_uf\n"
          "🚚 *Frete:* $_metodoEnvio (R\$ ${_valorFrete.toStringAsFixed(2)})\n"
          "💳 *Pagamento:* $_metodoPagamento\n\n"
          "📦 *Produtos:*\n";

      for (var item in cart.items) {
        mensagem +=
            "• ${item.quantity}x ${item.product.name} - R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}\n";
      }
      mensagem +=
          "\n💰 *Total Pedido Benta Laços: R\$ ${totalFinal.toStringAsFixed(2)}*";

      final url =
          "https://wa.me/5554999264865?text=${Uri.encodeComponent(mensagem)}";

      if (await canLaunchUrl(Uri.parse(url))) {
        await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
        cart.clearCart(); // Limpa o carrinho após abrir o WhatsApp
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Finalizar Pedido",
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: TemaSite.corPrimaria,
        iconTheme: const IconThemeData(color: Colors.white),
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
                  _buildBannerClienteOriginal(), // Banner Restaurado (2 Colunas)
                  const SizedBox(height: 20),
                  const Text(
                    "Resumo do Pedido",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildItensCarrinho(cart),
                  const Divider(),
                  const Text(
                    "1. Como deseja receber?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildOpcaoEnvio('Retirar na Loja', 0.0),
                  _buildOpcaoEnvio('Correios (PAC)', 29.90),
                  _buildOpcaoEnvio('Correios (SEDEX)', 54.90),
                  const SizedBox(height: 20),
                  const Text(
                    "2. Como deseja pagar?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildPagamento('Pix', Icons.pix, Colors.teal),
                  _buildPagamento(
                    'Cartão de Crédito',
                    Icons.credit_card,
                    Colors.pink,
                  ),
                  _buildPagamento(
                    'Cartão de Débito',
                    Icons.credit_card,
                    Colors.pink,
                  ), // Restaurado
                  if (_metodoPagamento.contains('Cartão'))
                    _buildFormCartao(totalFinal),
                  const Divider(height: 40),
                  _resumo("Subtotal Produtos", cart.total),
                  _resumo("Frete / Entrega", _valorFrete),
                  const SizedBox(height: 10),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "TOTAL",
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        "R\$ ${totalFinal.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                          color: TemaSite.corPrimaria,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 30),
                  ElevatedButton(
                    onPressed: _processando
                        ? null
                        : () => _finalizarPedido(cart),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _processando
                          ? Colors.grey
                          : const Color(0xFF4CAF50),
                      minimumSize: const Size(double.infinity, 55),
                    ),
                    child: _processando
                        ? const CircularProgressIndicator(color: Colors.white)
                        : const Text(
                            "ENVIAR PEDIDO",
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                  ),
                ],
              ),
            ),
    );
  }

  Widget _buildBannerClienteOriginal() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFE8F0),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.pink.shade100),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(Icons.person, "Cliente: $_nomeCompleto", Colors.blue),
                _infoRow(Icons.email, "E-mail: $_emailCliente", Colors.pink),
                _infoRow(Icons.phone, "Tel: $_telefoneCliente", Colors.black87),
                _infoRow(
                  Icons.cake,
                  "Nasc: $_nascimentoCliente",
                  Colors.orange,
                ),
              ],
            ),
          ),
          Container(
            height: 70,
            width: 1,
            color: Colors.black12,
            margin: const EdgeInsets.symmetric(horizontal: 10),
          ),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _infoRow(
                  Icons.location_on,
                  "End: $_endereco, $_numeroCasa",
                  Colors.red,
                ),
                _infoRow(Icons.home_work, "Bairro: $_bairro", Colors.brown),
                if (_complemento.isNotEmpty)
                  _infoRow(
                    Icons.info_outline,
                    "Comp: $_complemento",
                    Colors.blueGrey,
                  ),
                _infoRow(
                  Icons.location_city,
                  "Cidade: $_cidade - $_uf",
                  Colors.cyan,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(IconData icon, String text, Color color) => Padding(
    padding: const EdgeInsets.symmetric(vertical: 2),
    child: Row(
      children: [
        Icon(icon, size: 13, color: color),
        const SizedBox(width: 5),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w500),
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    ),
  );

  Widget _buildItensCarrinho(CartProvider cart) {
    return Column(
      children: cart.items
          .map(
            (item) => ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Image.network(
                item.product.imageUrl ?? '',
                width: 40,
                height: 40,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => const Icon(Icons.image),
              ),
              title: Text(
                item.product.name,
                style: const TextStyle(fontSize: 14),
              ),
              subtitle: Text(
                "${item.quantity}x R\$ ${item.product.price.toStringAsFixed(2)}",
              ),
              trailing: Text(
                "R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}",
              ),
            ),
          )
          .toList(),
    );
  }

  Widget _buildPagamento(String t, IconData i, Color c) => RadioListTile(
    title: Row(
      children: [
        Text(t),
        const Spacer(),
        Icon(i, color: c, size: 20),
      ],
    ),
    value: t,
    groupValue: _metodoPagamento,
    onChanged: (val) => setState(() => _metodoPagamento = val!),
  );

  Widget _buildOpcaoEnvio(String t, double v) => RadioListTile(
    title: Text(t),
    secondary: Text("R\$ ${v.toStringAsFixed(2)}"),
    value: t,
    groupValue: _metodoEnvio,
    onChanged: (val) => setState(() {
      _metodoEnvio = val!;
      _valorFrete = v;
    }),
  );

  Widget _buildFormCartao(double total) => Padding(
    padding: const EdgeInsets.all(10),
    child: Form(
      key: _formCartaoKey,
      child: Column(
        children: [
          if (_metodoPagamento == 'Cartão de Crédito')
            DropdownButtonFormField<int>(
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
            decoration: const InputDecoration(labelText: "Número do Cartão"),
            inputFormatters: [maskNumeroCartao],
            validator: (v) => v!.isEmpty ? "Obrigatório" : null,
          ),
          Row(
            children: [
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: "Validade"),
                  inputFormatters: [maskValidade],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextFormField(
                  decoration: const InputDecoration(labelText: "CVV"),
                  inputFormatters: [maskCVV],
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
      Text("R\$ ${v.toStringAsFixed(2)}"),
    ],
  );
}
