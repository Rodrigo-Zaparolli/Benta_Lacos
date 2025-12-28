import 'package:flutter/material.dart';
import 'package:benta_lacos/domain/models/product.dart';

class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider extends ChangeNotifier {
  // Alterado para CartProvider para facilitar no Checkout
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total =>
      _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  // Adicionar ou Aumentar
  void addItem(Product product, [int quantity = 1]) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  // Diminuir Quantidade (-)
  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index); // Se era 1, remove do carrinho
      }
      notifyListeners(); // ESSENCIAL para o reset do total na tela
    }
  }

  // Excluir Total (Lixeira)
  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners(); // ESSENCIAL para o reset do total na tela
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
