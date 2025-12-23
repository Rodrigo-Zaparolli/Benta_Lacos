import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../models/providers/cart_provider.dart';
import '../../tema/tema_site.dart';

class PaymentPage extends StatefulWidget {
  final CartProvider cart;
  final String nomeCliente;
  final String cepCliente;

  const PaymentPage({
    super.key,
    required this.cart,
    required this.nomeCliente,
    required this.cepCliente,
  });

  @override
  State<PaymentPage> createState() => _PaymentPageState();
}

class _PaymentPageState extends State<PaymentPage> {
  String metodoEntrega = 'Retirar na Loja';
  double valorFrete = 0.0;
  String metodoPagamento = 'Pix';
  int parcelas = 1;

  // Estados para busca de endereço e frete
  bool isLoading = true;
  String logradouro = "";
  String bairro = "";
  String cidade = "";
  String uf = "";
  double precoPac = 0.0;
  double precoSedex = 0.0;

  final cardMask = MaskTextInputFormatter(
    mask: '#### #### #### ####',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final dateMask = MaskTextInputFormatter(
    mask: '##/##',
    filter: {"#": RegExp(r'[0-9]')},
  );
  final cvvMask = MaskTextInputFormatter(
    mask: '###',
    filter: {"#": RegExp(r'[0-9]')},
  );

  @override
  void initState() {
    super.initState();
    _inicializarPagina();
  }

  /// Gerencia a busca do endereço e o cálculo do frete
  Future<void> _inicializarPagina() async {
    setState(() => isLoading = true);
    await _buscarEnderecoViaCep();
    await _calcularFrete();
    setState(() => isLoading = false);
  }

  /// Busca o endereço real pelo CEP informado
  Future<void> _buscarEnderecoViaCep() async {
    // Remove caracteres não numéricos do CEP
    final String cepLimpo = widget.cepCliente.replaceAll(RegExp(r'[^0-9]'), '');

    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          setState(() {
            logradouro = data['logradouro'];
            bairro = data['bairro'];
            cidade = data['localidade'];
            uf = data['uf'];
          });
        }
      }
    } catch (e) {
      debugPrint("Erro ao buscar CEP: $e");
    }
  }

  /// Simulação de cálculo de frete (Pode ser substituído por API do Melhor Envio/Correios)
  Future<void> _calcularFrete() async {
    // Lógica fictícia: Frete fixo baseado na UF
    // Rio Grande do Sul (RS) costuma ser mais barato para a Benta Laços (Nova Prata)
    if (uf == "RS") {
      precoPac = 15.90;
      precoSedex = 25.00;
    } else {
      precoPac = 29.90;
      precoSedex = 54.90;
    }
  }

  void atualizarFrete(String metodo, double valor) {
    setState(() {
      metodoEntrega = metodo;
      valorFrete = valor;
    });
  }

  Future<void> enviarWhatsApp() async {
    final double totalGeral = widget.cart.total + valorFrete;
    String detalhePagamento = metodoPagamento;

    if (metodoPagamento == 'Cartão de Crédito') {
      detalhePagamento +=
          " ($parcelas x de R\$ ${(totalGeral / parcelas).toStringAsFixed(2)})";
    }

    String listaProdutos = widget.cart.items
        .map(
          (item) =>
              "${item.quantity}x ${item.product.name} - R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}",
        )
        .join('\n');

    final String mensagem = Uri.encodeComponent(
      "NOVO PEDIDO - BENTA LAÇOS 🎀\n\n"
      "👤 Cliente: ${widget.nomeCliente}\n"
      "📍 Endereço: $logradouro, $bairro - $cidade/$uf\n"
      "📮 CEP: ${widget.cepCliente}\n\n"
      "🛒 Itens:\n$listaProdutos\n\n"
      "🚚 Entrega: $metodoEntrega (R\$ ${valorFrete.toStringAsFixed(2)})\n"
      "💳 Pagamento: $detalhePagamento\n\n"
      "💰 TOTAL: R\$ ${totalGeral.toStringAsFixed(2)}",
    );

    final Uri url = Uri.parse("https://wa.me/5554999264865?text=$mensagem");
    await launchUrl(url, mode: LaunchMode.externalApplication);
  }

  @override
  Widget build(BuildContext context) {
    final double totalFinal = widget.cart.total + valorFrete;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          "Finalizar Pedido",
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: TemaSite.corPrimaria,
        elevation: 0,
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : SingleChildScrollView(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildInfoEndereco(),
                  const SizedBox(height: 20),

                  const Text(
                    "Resumo do Pedido",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  _buildResumoItens(),

                  const SizedBox(height: 25),
                  const Text(
                    "1. Como deseja receber?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                  _buildOpcaoEntrega("Retirar na Loja", 0.0),
                  _buildOpcaoEntrega("Correios (PAC)", precoPac),
                  _buildOpcaoEntrega("Correios (SEDEX)", precoSedex),

                  const SizedBox(height: 25),
                  const Text(
                    "2. Como deseja pagar?",
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),

                  _buildOpcaoPagamento("Pix", FontAwesomeIcons.pix),
                  if (metodoPagamento == 'Pix') _buildPainelPix(),

                  _buildOpcaoPagamento("Cartão de Crédito", Icons.credit_card),
                  if (metodoPagamento == 'Cartão de Crédito') ...[
                    _buildPainelParcelas(totalFinal),
                    _buildFormularioCartao(),
                  ],

                  _buildOpcaoPagamento(
                    "Cartão de Débito",
                    Icons.credit_card_outlined,
                  ),
                  if (metodoPagamento == 'Cartão de Débito')
                    _buildFormularioCartao(),

                  const SizedBox(height: 30),
                  _buildResumoFinanceiro(totalFinal),

                  const SizedBox(height: 20),
                  _buildBotaoFinalizar(),
                ],
              ),
            ),
    );
  }

  Widget _buildInfoEndereco() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade100),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Entregar em:",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 12,
              color: Colors.blue,
            ),
          ),
          Text(
            logradouro.isEmpty
                ? "Endereço não localizado"
                : "$logradouro, $bairro",
            style: const TextStyle(fontSize: 14),
          ),
          Text(
            "$cidade - $uf (CEP: ${widget.cepCliente})",
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildResumoItens() {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFDFBFA),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: widget.cart.items
            .map(
              (item) => Padding(
                padding: const EdgeInsets.symmetric(vertical: 4),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${item.quantity}x ${item.product.name}"),
                    Text(
                      "R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}",
                    ),
                  ],
                ),
              ),
            )
            .toList(),
      ),
    );
  }

  Widget _buildFormularioCartao() {
    return Container(
      margin: const EdgeInsets.only(left: 45, top: 10, bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          TextField(
            inputFormatters: [cardMask],
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Número do Cartão",
              prefixIcon: Icon(Icons.credit_card),
            ),
          ),
          const SizedBox(height: 10),
          TextField(
            decoration: const InputDecoration(
              labelText: "Nome impresso no Cartão",
              prefixIcon: Icon(Icons.person),
            ),
          ),
          const SizedBox(height: 10),
          Row(
            children: [
              Expanded(
                child: TextField(
                  inputFormatters: [dateMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(
                    labelText: "Validade (MM/AA)",
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: TextField(
                  inputFormatters: [cvvMask],
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: "CVV"),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPainelPix() {
    const String chavePix = "54991147771";
    return Container(
      margin: const EdgeInsets.only(left: 45, top: 10, bottom: 10),
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        children: [
          const Text(
            "Escaneie o QR Code abaixo:",
            style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 15),
          QrImageView(
            data: chavePix,
            version: QrVersions.auto,
            size: 160.0,
            eyeStyle: const QrEyeStyle(
              eyeShape: QrEyeShape.square,
              color: Colors.black,
            ),
          ),
          const SizedBox(height: 15),
          const Divider(),
          const Text(
            "Ou copie a chave Pix:",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          Row(
            children: [
              Expanded(
                child: Text(
                  chavePix,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: TemaSite.corPrimaria,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.copy, size: 20, color: Colors.grey),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: chavePix));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chave Pix copiada!")),
                  );
                },
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPainelParcelas(double total) {
    return Container(
      margin: const EdgeInsets.only(left: 45, top: 10, bottom: 5),
      child: DropdownButtonFormField<int>(
        value: parcelas,
        decoration: const InputDecoration(
          labelText: "Escolha as parcelas",
          border: OutlineInputBorder(),
        ),
        items: [1, 2, 3]
            .map(
              (int value) => DropdownMenuItem<int>(
                value: value,
                child: Text(
                  "$value x de R\$ ${(total / value).toStringAsFixed(2)}",
                ),
              ),
            )
            .toList(),
        onChanged: (val) => setState(() => parcelas = val!),
      ),
    );
  }

  Widget _buildOpcaoEntrega(String titulo, double valor) {
    return RadioListTile(
      title: Text(titulo),
      secondary: Text("R\$ ${valor.toStringAsFixed(2)}"),
      value: titulo,
      groupValue: metodoEntrega,
      activeColor: TemaSite.corPrimaria,
      onChanged: (value) => atualizarFrete(value.toString(), valor),
    );
  }

  Widget _buildOpcaoPagamento(String titulo, IconData icone) {
    return RadioListTile(
      title: Text(titulo),
      secondary: FaIcon(icone, color: TemaSite.corPrimaria, size: 20),
      value: titulo,
      groupValue: metodoPagamento,
      activeColor: TemaSite.corPrimaria,
      onChanged: (value) => setState(() => metodoPagamento = value.toString()),
    );
  }

  Widget _buildResumoFinanceiro(double total) {
    return Column(
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Subtotal"),
            Text("R\$ ${widget.cart.total.toStringAsFixed(2)}"),
          ],
        ),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text("Frete"),
            Text("R\$ ${valorFrete.toStringAsFixed(2)}"),
          ],
        ),
        const Divider(),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              "TOTAL",
              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
            ),
            Text(
              "R\$ ${total.toStringAsFixed(2)}",
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 22,
                color: TemaSite.corPrimaria,
              ),
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildBotaoFinalizar() {
    return ElevatedButton(
      onPressed: enviarWhatsApp,
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.green.shade600,
        minimumSize: const Size(double.infinity, 60),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
      ),
      child: const Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          FaIcon(FontAwesomeIcons.whatsapp, color: Colors.white),
          SizedBox(width: 10),
          Text(
            "ENVIAR PEDIDO VIA WHATSAPP",
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
