import 'package:flutter/material.dart';
import '../models/product.dart';

// Modelo do Item do Carrinho
class CartItem {
  final Product product;
  int quantity;

  CartItem({required this.product, this.quantity = 1});
}

class CartProvider with ChangeNotifier {
  // Usando List conforme sua preferência atual
  final List<CartItem> _items = [];

  List<CartItem> get items => [..._items];

  // Retorna a quantidade total de itens (útil para o ícone de badge)
  int get itemCount {
    return _items.fold(0, (sum, item) => sum + item.quantity);
  }

  double get total {
    double total = 0.0;
    for (var item in _items) {
      total += item.product.price * item.quantity;
    }
    return total;
  }

  // Adiciona item ou aumenta quantidade específica
  void addItem(Product product, [int quantity = 1]) {
    int index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index].quantity += quantity;
    } else {
      _items.add(CartItem(product: product, quantity: quantity));
    }
    notifyListeners();
  }

  // Remove uma unidade (se chegar a 1, remove o item da lista)
  void removeSingleItem(String productId) {
    int index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
      } else {
        _items.removeAt(index);
      }
      notifyListeners();
    }
  }

  // Remove o item completamente da lista (botão excluir ou slide)
  void clearItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);
    notifyListeners();
  }

  // AJUSTADO: Nome alterado para 'clear' para bater com a chamada na CartScreen
  void clear() {
    _items.clear();
    notifyListeners();
  }
}
