import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:benta_lacos/models/providers/cart_provider.dart';
import 'package:benta_lacos/tema/tema_site.dart';
import 'package:benta_lacos/models/product.dart';
import '../payment/payment_page.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Escutando as mudanças do carrinho
    final cart = Provider.of<CartProvider>(context);

    // Dados fictícios para o exemplo (no futuro virão do login)
    const String nomeClienteLogado = "Cliente Benta Laços";
    const String cepClienteLogado = "00000-000";

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.close, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meu Carrinho',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: TemaSite.corPrimaria,
        elevation: 0,
      ),
      body: Column(
        children: [
          Expanded(
            child: cart.items.isEmpty
                ? const Center(child: Text("Seu carrinho está vazio 🎀"))
                : ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildItemCarrinho(context, cart, item);
                    },
                  ),
          ),
          _buildBotaoProsseguir(
            context,
            cart,
            nomeClienteLogado,
            cepClienteLogado,
          ),
        ],
      ),
    );
  }

  Widget _buildItemCarrinho(
    BuildContext context,
    CartProvider cart,
    dynamic item,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF5EE), // Cor pêssego suave das suas imagens
        borderRadius: BorderRadius.circular(15),
      ),
      child: Row(
        children: [
          // IMAGEM DO PRODUTO
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: _gerarImagem(item.product),
          ),
          const SizedBox(width: 12),

          // NOME E PREÇO
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.product.name,
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  "R\$ ${(item.product.price * item.quantity).toStringAsFixed(2)}",
                  style: const TextStyle(
                    color: TemaSite.corPrimaria,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),

          // CONTROLES DE QUANTIDADE (- E +)
          Row(
            children: [
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.remove_circle_outline,
                  color: Colors.grey,
                ),
                onPressed: () {
                  // Diminuir quantidade (garanta que este método existe no seu provider)
                  cart.removeSingleItem(item.product.id);
                },
              ),
              Text(
                "${item.quantity}",
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
              IconButton(
                visualDensity: VisualDensity.compact,
                icon: const Icon(
                  Icons.add_circle_outline,
                  color: TemaSite.corPrimaria,
                ),
                onPressed: () {
                  // Aumentar quantidade
                  cart.addItem(item.product);
                },
              ),
            ],
          ),

          // BOTÃO LIXEIRA (REMOVER TUDO)
          IconButton(
            icon: const Icon(Icons.delete_outline, color: Colors.redAccent),
            onPressed: () {
              // Remover item completamente
              cart.clearItem(item.product.id);
            },
          ),
        ],
      ),
    );
  }

  Widget _gerarImagem(Product p) {
    if (p.imageBytes != null) {
      return Image.memory(
        p.imageBytes!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      );
    }
    if (p.imagePath != null) {
      return Image.asset(
        p.imagePath!,
        width: 60,
        height: 60,
        fit: BoxFit.cover,
      );
    }
    return const Icon(Icons.image, size: 60);
  }

  Widget _buildBotaoProsseguir(
    BuildContext context,
    CartProvider cart,
    String nome,
    String cep,
  ) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: const BoxDecoration(
        color: Color(0xFFFDFBFA),
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(30),
          topRight: Radius.circular(30),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 10,
            offset: Offset(0, -5),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Total:", style: TextStyle(fontSize: 18)),
              Text(
                "R\$ ${cart.total.toStringAsFixed(2)}",
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: TemaSite.corPrimaria,
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: cart.items.isEmpty
                ? null
                : () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => PaymentPage(
                          cart: cart,
                          nomeCliente: nome,
                          cepCliente: cep,
                        ),
                      ),
                    );
                  },
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaSite.corPrimaria,
              minimumSize: const Size(double.infinity, 55),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
            child: const Text(
              "PROSSEGUIR PARA PAGAMENTO",
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
