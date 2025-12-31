import 'package:flutter/material.dart';
import 'package:benta_lacos/domain/models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  bool selecionado; // Adicionado para não quebrar o checkout

  CartItem({
    required this.product,
    this.quantity = 1,
    this.selecionado = true, // Adicionado
  });
}

class CartProvider extends ChangeNotifier {
  final List<CartItem> _items = [];

  List<CartItem> get items => _items;

  double get total =>
      _items.fold(0, (sum, item) => sum + (item.product.price * item.quantity));

  void addItem(Product product, [int quantity = 1]) {
    final index = _items.indexWhere((item) => item.product.id == product.id);

    if (index != -1) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  void decrementQuantity(String productId) {
    final index = _items.indexWhere((item) => item.product.id == productId);

    if (index != -1) {
      if (_items[index].quantity > 1) {
        _items[index].quantity--;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  void removeItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  void clearCart() {
    _items.clear();
    notifyListeners();
  }
}
