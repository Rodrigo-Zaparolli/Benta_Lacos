import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:qr_flutter/qr_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import '../../../domain/providers/cart_provider.dart';
import '../../../shared/theme/tema_site.dart';

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
  String metodoPagamento = 'Pix'; // Valor inicial
  int parcelas = 1;

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

  Future<void> _inicializarPagina() async {
    setState(() => isLoading = true);
    await _buscarEnderecoViaCep();
    await _calcularFrete();
    setState(() => isLoading = false);
  }

  Future<void> _buscarEnderecoViaCep() async {
    final String cepLimpo = widget.cepCliente.replaceAll(RegExp(r'[^0-9]'), '');
    try {
      final response = await http.get(
        Uri.parse('https://viacep.com.br/ws/$cepLimpo/json/'),
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['erro'] == null) {
          setState(() {
            logradouro = data['logradouro'] ?? "";
            bairro = data['bairro'] ?? "";
            cidade = data['localidade'] ?? "";
            uf = data['uf'] ?? "";
          });
        }
      }
    } catch (e) {
      debugPrint("Erro CEP: $e");
    }
  }

  Future<void> _calcularFrete() async {
    if (uf == "RS") {
      precoPac = 15.90;
      precoSedex = 25.00;
    } else {
      precoPac = 29.90;
      precoSedex = 54.90;
    }
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
        iconTheme: const IconThemeData(color: Colors.white),
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

                  // LISTA DE OPÇÕES DE PAGAMENTO
                  _buildListaPagamentos(totalFinal),

                  const SizedBox(height: 30),
                  _buildResumoFinanceiro(totalFinal),
                  const SizedBox(height: 20),
                  _buildBotaoFinalizar(),
                ],
              ),
            ),
    );
  }

  // --- WIDGET QUE GERENCIA A EXIBIÇÃO DINÂMICA ---
  Widget _buildListaPagamentos(double totalFinal) {
    return Column(
      children: [
        // OPÇÃO PIX
        RadioListTile<String>(
          title: const Text("Pix"),
          secondary: const FaIcon(
            FontAwesomeIcons.pix,
            color: Colors.teal,
            size: 20,
          ),
          value: "Pix",
          groupValue: metodoPagamento,
          activeColor: TemaSite.corPrimaria,
          onChanged: (value) => setState(() => metodoPagamento = value!),
        ),
        if (metodoPagamento == 'Pix') _buildPainelPix(),

        // OPÇÃO CRÉDITO
        RadioListTile<String>(
          title: const Text("Cartão de Crédito"),
          secondary: const Icon(Icons.credit_card, color: Colors.blue),
          value: "Cartão de Crédito",
          groupValue: metodoPagamento,
          activeColor: TemaSite.corPrimaria,
          onChanged: (value) => setState(() => metodoPagamento = value!),
        ),
        if (metodoPagamento == 'Cartão de Crédito') ...[
          _buildPainelParcelas(totalFinal),
          _buildFormularioCartao(),
        ],

        // OPÇÃO DÉBITO
        RadioListTile<String>(
          title: const Text("Cartão de Débito"),
          secondary: const Icon(
            Icons.credit_card_outlined,
            color: Colors.orange,
          ),
          value: "Cartão de Débito",
          groupValue: metodoPagamento,
          activeColor: TemaSite.corPrimaria,
          onChanged: (value) => setState(() => metodoPagamento = value!),
        ),
        if (metodoPagamento == 'Cartão de Débito') _buildFormularioCartao(),
      ],
    );
  }

  Widget _buildPainelPix() {
    const String chavePix = "54991147771";
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.symmetric(vertical: 10, horizontal: 10),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.teal.withOpacity(0.05),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: Colors.teal.withOpacity(0.2)),
      ),
      child: Column(
        children: [
          const Text(
            "Pagamento Instantâneo",
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
          ),
          const SizedBox(height: 15),
          // QR CODE
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
            ),
            child: QrImageView(
              data: chavePix,
              version: QrVersions.auto,
              size: 180.0,
              gapless: false,
            ),
          ),
          const SizedBox(height: 15),
          const Text(
            "Chave Pix (Celular):",
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 5),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text(
                chavePix,
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
              ),
              const SizedBox(width: 10),
              IconButton(
                icon: const Icon(Icons.copy, color: Colors.teal),
                onPressed: () {
                  Clipboard.setData(const ClipboardData(text: chavePix));
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text("Chave Pix copiada!")),
                  );
                },
              ),
            ],
          ),
          const Text(
            "Após o pagamento, envie o comprovante pelo WhatsApp.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 11,
              color: Colors.teal,
              fontStyle: FontStyle.italic,
            ),
          ),
        ],
      ),
    );
  }

  // ... (Restante dos widgets auxiliares permanecem iguais ao anterior)

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
                ? "Carregando endereço..."
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
      margin: const EdgeInsets.only(left: 10, top: 10, bottom: 10),
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
          const TextField(
            decoration: InputDecoration(
              labelText: "Nome no Cartão",
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

  Widget _buildPainelParcelas(double total) {
    return Container(
      margin: const EdgeInsets.only(left: 10, top: 10, bottom: 5),
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
      onChanged: (value) {
        setState(() {
          metodoEntrega = value.toString();
          valorFrete = valor;
        });
      },
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
