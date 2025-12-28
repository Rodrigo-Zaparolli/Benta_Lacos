// lib/pages/payment/pix_payment_page.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:confetti/confetti.dart';
import 'package:url_launcher/url_launcher.dart';

import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';

class PixPaymentPage extends StatefulWidget {
  final String nomeCliente;

  const PixPaymentPage({super.key, required this.nomeCliente});

  @override
  State<PixPaymentPage> createState() => _PixPaymentPageState();
}

class _PixPaymentPageState extends State<PixPaymentPage> {
  late ConfettiController _confettiController;

  @override
  void initState() {
    super.initState();
    _confettiController = ConfettiController(
      duration: const Duration(seconds: 2),
    );
  }

  @override
  void dispose() {
    _confettiController.dispose();
    super.dispose();
  }

  Future<void> _finalizarPedido(CartProvider cart) async {
    _confettiController.play();

    final mensagem = Uri.encodeComponent(
      "🎀 *NOVO PEDIDO (PIX) - BENTA LAÇOS*\n"
      "👤 *Cliente:* ${widget.nomeCliente}\n"
      "💰 *Total: R\$ ${cart.total.toStringAsFixed(2)}*\n"
      "✅ Já realizei o pagamento via Pix!",
    );

    final url = "https://wa.me/5554999714428?text=$mensagem";

    await Future.delayed(const Duration(milliseconds: 1500));
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
      cart.clear();
      if (mounted) Navigator.of(context).popUntil((route) => route.isFirst);
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);

    return Stack(
      alignment: Alignment.topCenter,
      children: [
        Scaffold(
          appBar: AppBar(
            title: const Text("Pagamento Pix"),
            backgroundColor: TemaSite.corPrimaria,
          ),
          body: Padding(
            padding: const EdgeInsets.all(25),
            child: Column(
              children: [
                const Icon(Icons.pix, color: Color(0xFF32BCAD), size: 80),
                const SizedBox(height: 20),
                const Text(
                  "Chave Pix (Celular)",
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 10),
                Container(
                  padding: const EdgeInsets.all(15),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: const Text(
                    "5554999714428",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                ),
                TextButton.icon(
                  onPressed: () {
                    Clipboard.setData(
                      const ClipboardData(text: "5554999714428"),
                    );
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text("Copiado!")));
                  },
                  icon: const Icon(Icons.copy),
                  label: const Text("COPIAR CHAVE"),
                ),
                const Spacer(),
                ElevatedButton(
                  onPressed: () => _finalizarPedido(cart),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: TemaSite.corDestaque,
                    minimumSize: const Size(double.infinity, 55),
                  ),
                  child: const Text(
                    "JÁ PAGUEI / ENVIAR WHATSAPP",
                    style: TextStyle(color: Colors.white),
                  ),
                ),
              ],
            ),
          ),
        ),
        ConfettiWidget(
          confettiController: _confettiController,
          blastDirectionality: BlastDirectionality.explosive,
        ),
      ],
    );
  }
}
