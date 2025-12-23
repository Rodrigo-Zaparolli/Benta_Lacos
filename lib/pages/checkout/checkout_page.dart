import 'package:benta_lacos/pages/payment/payment_page.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../tema/tema_site.dart';
import '../../models/providers/cart_provider.dart';

class CheckoutPage extends StatelessWidget {
  final String nomeCliente;
  final String cepCliente;

  const CheckoutPage({
    super.key,
    required this.nomeCliente,
    required this.cepCliente,
  });

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    const Color corTexto = Color(0xFF5D4538);

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: corTexto),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Revisão do Pedido',
          style: TextStyle(color: corTexto, fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Olá, $nomeCliente! ✨',
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: TemaSite.corPrimaria,
              ),
            ),
            const SizedBox(height: 5),
            const Text(
              'Confira os itens antes de pagar:',
              style: TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 25),

            // LISTA DETALHADA DOS ITENS
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(20),
                color: Colors.grey.shade50,
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  ...cart.items
                      .map(
                        (item) => Padding(
                          padding: const EdgeInsets.symmetric(vertical: 8.0),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Expanded(
                                child: Text(
                                  // REMOVIDO: O ID [#p1] foi retirado daqui
                                  "${item.quantity}x ${item.product.name}",
                                  style: const TextStyle(
                                    color: corTexto,
                                    fontSize: 16,
                                  ),
                                ),
                              ),
                              Text(
                                "R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}",
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: corTexto,
                                ),
                              ),
                            ],
                          ),
                        ),
                      )
                      .toList(),
                  const Divider(height: 30),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        "Total do Pedido",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 18,
                          color: corTexto,
                        ),
                      ),
                      Text(
                        "R\$ ${cart.total.toStringAsFixed(2)}",
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 22,
                          color: TemaSite.corPrimaria,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const SizedBox(height: 40),

            ElevatedButton(
              onPressed: cart.items.isEmpty
                  ? null
                  : () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PaymentPage(
                            cart: cart,
                            nomeCliente: nomeCliente,
                            cepCliente: cepCliente,
                          ),
                        ),
                      );
                    },
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaSite.corDestaque,
                minimumSize: const Size(double.infinity, 65),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(18),
                ),
                elevation: 2,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "CONTINUAR PARA PAGAMENTO",
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.white,
                    ),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward, color: Colors.white),
                ],
              ),
            ),

            const SizedBox(height: 20),
            Center(
              child: TextButton(
                onPressed: () => Navigator.pop(context),
                child: const Text(
                  "Alterar itens ou nome",
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildLogoFooter(corTexto),
    );
  }

  Widget _buildLogoFooter(Color cor) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text('🎀 ', style: TextStyle(fontSize: 20)),
            Text(
              'Benta Laços',
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: cor,
                fontSize: 16,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
