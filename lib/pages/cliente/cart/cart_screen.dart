import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_slidable/flutter_slidable.dart'; // Sugestão: adicione no pubspec.yaml
import 'package:benta_lacos/domain/providers/cart_provider.dart';
import 'package:benta_lacos/shared/theme/tema_site.dart';
import 'package:benta_lacos/domain/models/product.dart';
import '../checkout/checkout_page.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final cart = Provider.of<CartProvider>(context);
    const double valorParaFreteGratis = 150.0; // Exemplo de regra de negócio

    return Scaffold(
      backgroundColor: const Color(
        0xFFF8F9FA,
      ), // Fundo levemente cinza para destacar os cards brancos
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(
            Icons.arrow_back_ios_new_rounded,
            color: Colors.black87,
            size: 20,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: const Text(
          'Meu Carrinho',
          style: TextStyle(
            color: Colors.black87,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        actions: [
          if (cart.items.isNotEmpty)
            IconButton(
              icon: const Icon(
                Icons.delete_sweep_outlined,
                color: Colors.redAccent,
              ),
              onPressed: () => _confirmarLimparCarrinho(context, cart),
            ),
        ],
      ),
      body: Column(
        children: [
          // Upgrade 1: Barra de Frete Grátis
          if (cart.items.isNotEmpty)
            _buildBarraFrete(cart.total, valorParaFreteGratis),

          Expanded(
            child: cart.items.isEmpty
                ? _buildCarrinhoVazio(context)
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 10,
                    ),
                    itemCount: cart.items.length,
                    itemBuilder: (context, index) {
                      final item = cart.items[index];
                      return _buildItemCarrinhoPremium(context, cart, item);
                    },
                  ),
          ),
          _buildResumoPremium(context, cart),
        ],
      ),
    );
  }

  // Upgrade 2: Barra de Progresso Motivacional
  Widget _buildBarraFrete(double total, double meta) {
    double progresso = (total / meta).clamp(0.0, 1.0);
    double faltante = meta - total;

    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          Row(
            children: [
              Icon(
                Icons.local_shipping_outlined,
                color: progresso >= 1 ? Colors.green : TemaSite.corPrimaria,
                size: 20,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  progresso >= 1
                      ? "Parabéns! Você ganhou Frete Grátis! 🎀"
                      : "Faltam R\$ ${faltante.toStringAsFixed(2)} para Frete Grátis",
                  style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          LinearProgressIndicator(
            value: progresso,
            backgroundColor: Colors.grey[200],
            color: progresso >= 1 ? Colors.green : TemaSite.corPrimaria,
            borderRadius: BorderRadius.circular(10),
            minHeight: 6,
          ),
        ],
      ),
    );
  }

  Widget _buildCarrinhoVazio(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(30),
            decoration: BoxDecoration(
              color: TemaSite.corPrimaria.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              Icons.shopping_basket_outlined,
              size: 100,
              color: TemaSite.corPrimaria,
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            "Seu carrinho está vazio",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            "Que tal adicionar alguns laços lindos hoje?",
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 30),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            style: ElevatedButton.styleFrom(
              backgroundColor: TemaSite.corPrimaria,
              padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(30),
              ),
            ),
            child: const Text(
              "IR ÀS COMPRAS",
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

  // Upgrade 3: Card com Slidable (Arrastar para excluir) e Design Moderno
  Widget _buildItemCarrinhoPremium(
    BuildContext context,
    CartProvider cart,
    dynamic item,
  ) {
    final Product produto = item.product;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Slidable(
        key: ValueKey(produto.id),
        endActionPane: ActionPane(
          motion: const ScrollMotion(),
          extentRatio: 0.25,
          children: [
            SlidableAction(
              onPressed: (_) => cart.clearItem(produto.id),
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              icon: Icons.delete_outline,
              label: 'Excluir',
              borderRadius: BorderRadius.circular(16),
            ),
          ],
        ),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: Colors.grey.shade100),
          ),
          child: Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: SizedBox(
                  width: 85,
                  height: 85,
                  child: Hero(
                    tag: 'cart_${produto.id}',
                    child: _gerarImagem(produto),
                  ),
                ),
              ),
              const SizedBox(width: 15),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      produto.name,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      "R\$ ${produto.price.toStringAsFixed(2)}",
                      style: TextStyle(color: Colors.grey[600], fontSize: 14),
                    ),
                    const SizedBox(height: 10),
                    // Seletor de Quantidade Moderno
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: Colors.grey[100],
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Row(
                            children: [
                              _botaoQuantidade(
                                Icons.remove,
                                () => cart.removeSingleItem(produto.id),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                ),
                                child: Text(
                                  "${item.quantity}",
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              _botaoQuantidade(
                                Icons.add,
                                () => cart.addItem(produto),
                              ),
                            ],
                          ),
                        ),
                        Text(
                          "R\$ ${(produto.price * item.quantity).toStringAsFixed(2)}",
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.black87,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _botaoQuantidade(IconData icon, VoidCallback onTap) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.all(6),
        child: Icon(icon, size: 18, color: Colors.black54),
      ),
    );
  }

  Widget _gerarImagem(Product p) {
    if (p.imageUrl != null && p.imageUrl!.isNotEmpty) {
      return Image.network(p.imageUrl!, fit: BoxFit.cover);
    }
    return Container(color: Colors.grey[200], child: const Icon(Icons.image));
  }

  Widget _buildResumoPremium(BuildContext context, CartProvider cart) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(30)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 20,
            offset: const Offset(0, -5),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Subtotal",
                  style: TextStyle(color: Colors.grey, fontSize: 15),
                ),
                Text(
                  "R\$ ${cart.total.toStringAsFixed(2)}",
                  style: const TextStyle(fontSize: 15),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Total",
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
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
                  : () => _verificarAutenticacao(context),
              style: ElevatedButton.styleFrom(
                backgroundColor: TemaSite.corPrimaria,
                foregroundColor: Colors.white,
                minimumSize: const Size(double.infinity, 55),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                elevation: 0,
              ),
              child: const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    "FINALIZAR PEDIDO",
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  SizedBox(width: 10),
                  Icon(Icons.arrow_forward_rounded, size: 20),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _confirmarLimparCarrinho(BuildContext context, CartProvider cart) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Limpar Carrinho"),
        content: const Text("Deseja remover todos os itens do seu carrinho?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("CANCELAR"),
          ),
          TextButton(
            onPressed: () {
              cart.clear();
              Navigator.pop(ctx);
            },
            child: const Text("LIMPAR", style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );
  }

  void _verificarAutenticacao(BuildContext context) {
    final User? user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Por favor, faça login para finalizar seu pedido 🎀"),
          backgroundColor: Colors.orange,
          behavior: SnackBarBehavior.floating,
        ),
      );
      // Navigator.pushNamed(context, '/login');
    } else {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (_) => const CheckoutPage()),
      );
    }
  }
}
