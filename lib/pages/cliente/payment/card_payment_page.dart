// lib/pages/payment/card_payment_page.dart

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';

class CardPaymentPage extends StatefulWidget {
  final String nomeCliente;
  final bool isCredito;

  const CardPaymentPage({
    super.key,
    required this.nomeCliente,
    required this.isCredito,
  });

  @override
  State<CardPaymentPage> createState() => _CardPaymentPageState();
}

class _CardPaymentPageState extends State<CardPaymentPage> {
  String? _parcelaSelecionada;

  Widget _buildTextField(String label, {bool obscure = false}) {
    return TextField(
      obscureText: obscure,
      decoration: InputDecoration(
        labelText: label,
        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.isCredito ? "Cartão de Crédito" : "Cartão de Débito",
        ),
        backgroundColor: TemaSite.corPrimaria,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(25),
        child: Column(
          children: [
            if (widget.isCredito) ...[
              DropdownButtonFormField<String>(
                decoration: const InputDecoration(labelText: "Parcelas"),
                items: [1, 2, 3]
                    .map(
                      (p) => DropdownMenuItem(
                        value: "$p",
                        child: Text(
                          "$p"
                          "x de R\$ ${(cart.total / p).toStringAsFixed(2)}",
                        ),
                      ),
                    )
                    .toList(),
                onChanged: (v) => setState(() => _parcelaSelecionada = v),
              ),
              const SizedBox(height: 20),
            ],
            _buildTextField("Número do Cartão"),
            const SizedBox(height: 15),
            _buildTextField("Nome no Cartão"),
            const SizedBox(height: 15),
            Row(
              children: [
                Expanded(child: _buildTextField("Validade")),
                const SizedBox(width: 10),
                Expanded(child: _buildTextField("CVV", obscure: true)),
              ],
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () async {
                final msg = Uri.encodeComponent(
                  "🎀 *PEDIDO CARTÃO*\nCliente: ${widget.nomeCliente}\nTotal: R\$ ${cart.total.toStringAsFixed(2)}",
                );
                launchUrl(Uri.parse("https://wa.me/5554999714428?text=$msg"));
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaSite.corDestaque,
                minimumSize: const Size(double.infinity, 55),
              ),
              child: const Text(
                "CONFIRMAR E ENVIAR",
                style: TextStyle(color: Colors.white),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
