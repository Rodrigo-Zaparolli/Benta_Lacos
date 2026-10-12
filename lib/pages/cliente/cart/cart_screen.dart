import '../../../core/config/store_environment.dart';
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:provider/provider.dart';
import '../../../domain/providers/cart_provider.dart';
import '../../../shared/constants/card.dart';
import '../../../shared/utils/store_format.dart';
import '../../../shared/theme/tema_site.dart';

class CartScreen extends StatelessWidget {
  const CartScreen({super.key});
  void _checkout(BuildContext context) {
    if (FirebaseAuth.instance.currentUser == null) {
      showDialog(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Entre para continuar'),
          content: const Text(
            'Sua conta permite registrar e acompanhar o pedido. Os produtos continuam no carrinho.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Voltar'),
            ),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(dialogContext);
                Navigator.pushNamed(context, '/login');
              },
              child: const Text('Entrar na minha conta'),
            ),
          ],
        ),
      );
    } else {
      Navigator.pushNamed(context, '/checkout');
    }
  }

  @override
  Widget build(BuildContext context) {
    final cart = context.watch<CartProvider>();
    final selected = cart.items.where((i) => i.selecionado).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('Meu carrinho')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 900),
          child: Column(
            children: [
              Expanded(
                child: cart.items.isEmpty
                    ? Center(
                        child: Padding(
                          padding: const EdgeInsets.all(24),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(
                                Icons.shopping_bag_outlined,
                                size: 72,
                                color: TemaSite.corPrimaria,
                              ),
                              const SizedBox(height: 20),
                              const Text(
                                'Seu carrinho está vazio',
                                style: TextStyle(
                                  fontSize: 22,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 12),
                              const Text(
                                'Escolha os detalhes que vão acompanhar seus pequenos momentos.',
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: () =>
                                    Navigator.pushNamed(context, '/colecao'),
                                child: const Text('Conhecer a coleção'),
                              ),
                            ],
                          ),
                        ),
                      )
                    : ListView.separated(
                        padding: const EdgeInsets.all(16),
                        itemCount: cart.items.length,
                        separatorBuilder: (_, __) => const SizedBox(height: 16),
                        itemBuilder: (context, index) {
                          final item = cart.items[index];
                          return Card(
                            elevation: 0,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Checkbox(
                                        value: item.selecionado,
                                        onChanged: (_) => cart.toggleSelection(
                                          item.product.id,
                                        ),
                                        semanticLabel:
                                            'Selecionar ${item.product.name}',
                                      ),
                                      SizedBox(
                                        width: 64,
                                        height: 72,
                                        child: buildProductImage(
                                          item.product,
                                          width: 64,
                                          height: 72,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              item.product.name,
                                              style: const TextStyle(
                                                fontWeight: FontWeight.w600,
                                              ),
                                            ),
                                            const SizedBox(height: 8),
                                            Text(
                                              formatMoney(item.product.price),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 12),
                                  Wrap(
                                    spacing: 12,
                                    runSpacing: 8,
                                    crossAxisAlignment:
                                        WrapCrossAlignment.center,
                                    alignment: WrapAlignment.end,
                                    children: [
                                      Row(
                                        mainAxisSize: MainAxisSize.min,
                                        children: [
                                          IconButton(
                                            tooltip: 'Diminuir quantidade',
                                            onPressed: () =>
                                                cart.removeSingleItem(
                                                  item.product.id,
                                                ),
                                            icon: const Icon(Icons.remove),
                                          ),
                                          Text('${item.quantity}'),
                                          IconButton(
                                            tooltip: 'Aumentar quantidade',
                                            onPressed:
                                                StoreEnvironment.isTest ||
                                                    item.quantity <
                                                        item
                                                            .product
                                                            .purchaseLimit
                                                ? () =>
                                                      cart.addItem(item.product)
                                                : null,
                                            icon: const Icon(Icons.add),
                                          ),
                                        ],
                                      ),
                                      Text(
                                        formatMoney(
                                          item.quantity * item.product.price,
                                        ),
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      IconButton(
                                        tooltip: 'Remover produto',
                                        onPressed: () =>
                                            cart.clearItem(item.product.id),
                                        icon: const Icon(Icons.delete_outline),
                                      ),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
              ),
              if (cart.items.isNotEmpty)
                SafeArea(
                  top: false,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Subtotal (${selected.fold(0, (int n, i) => n + i.quantity)} itens): ${formatMoney(cart.total)}',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Entrega e pagamento serão combinados pelo atendimento.',
                          style: TextStyle(fontSize: 12),
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: selected.isEmpty
                              ? null
                              : () => _checkout(context),
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.all(18),
                          ),
                          child: const Text('Revisar pedido'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
