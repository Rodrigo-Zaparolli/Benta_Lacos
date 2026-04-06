import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  bool selecionado;

  CartItem({required this.product, this.quantity = 1, this.selecionado = true});

  // ✅ ADICIONADO (RESOLVE SEU ERRO)
  Map<String, dynamic> toMap() {
    return {
      'product': product.toMap(),
      'quantity': quantity,
      'selecionado': selecionado,
    };
  }

  // ✅ EXTRA (PROFISSIONAL)
  factory CartItem.fromMap(Map<String, dynamic> map, String productId) {
    return CartItem(
      product: Product.fromMap(map['product'], productId),
      quantity: (map['quantity'] as num? ?? 1).toInt(),
      selecionado: map['selecionado'] as bool? ?? true,
    );
  }
}

class CartProvider with ChangeNotifier {
  final List<CartItem> _items = [];
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  List<CartItem> get items => [..._items];

  int get itemCount => _items.fold(0, (sum, item) => sum + item.quantity);

  double get total {
    double total = 0.0;
    for (var item in _items) {
      if (item.selecionado) {
        total += item.product.price * item.quantity;
      }
    }
    return total;
  }

  Future<void> limparItensComprados() async {
    final user = _auth.currentUser;

    final itensParaRemover = _items.where((item) => item.selecionado).toList();

    if (user != null && itensParaRemover.isNotEmpty) {
      try {
        final batch = _firestore.batch();
        for (var item in itensParaRemover) {
          final cartRef = _firestore
              .collection('usuarios')
              .doc(user.uid)
              .collection('carrinho')
              .doc(item.product.id);
          batch.delete(cartRef);
        }
        await batch.commit();
      } catch (e) {
        debugPrint("Erro ao limpar itens comprados no Firestore: $e");
      }
    }

    _items.removeWhere((item) => item.selecionado);
    notifyListeners();
  }

  void clear() {
    _items.clear();
    notifyListeners();
  }

  void toggleSelection(String productId) {
    int index = _items.indexWhere((item) => item.product.id == productId);
    if (index >= 0) {
      _items[index].selecionado = !(_items[index].selecionado);
      _atualizarNoFirestore(_items[index]);
      notifyListeners();
    }
  }

  Future<void> sincronizarDoFirestore(String uid) async {
    try {
      _items.clear();

      final cartSnapshot = await _firestore
          .collection('usuarios')
          .doc(uid)
          .collection('carrinho')
          .get();

      for (var doc in cartSnapshot.docs) {
        final data = doc.data();

        // ✅ USANDO fromMap (mais limpo agora)
        _items.add(CartItem.fromMap(data, doc.id));
      }

      final favSnapshot = await _firestore
          .collection('usuarios')
          .doc(uid)
          .collection('favoritos')
          .get();

      for (var doc in favSnapshot.docs) {
        final data = doc.data();
        bool jaExiste = _items.any((item) => item.product.id == doc.id);

        if (!jaExiste) {
          _items.add(CartItem.fromMap(data, doc.id));
        }
      }

      notifyListeners();
    } catch (e) {
      debugPrint("Erro ao sincronizar: $e");
    }
  }

  Future<void> moverParaFavoritosELimpar() async {
    final user = _auth.currentUser;
    if (user == null) {
      clear();
      return;
    }

    try {
      if (_items.isNotEmpty) {
        final batch = _firestore.batch();

        for (var item in _items) {
          final favRef = _firestore
              .collection('usuarios')
              .doc(user.uid)
              .collection('favoritos')
              .doc(item.product.id);

          batch.set(favRef, item.toMap()); // ✅ MELHORADO

          final cartRef = _firestore
              .collection('usuarios')
              .doc(user.uid)
              .collection('carrinho')
              .doc(item.product.id);

          batch.delete(cartRef);
        }

        await batch.commit();
      }

      clear();
    } catch (e) {
      debugPrint("Erro no logout: $e");
    }
  }

  void addItem(Product product, [int quantity = 1]) {
    int index = _items.indexWhere((item) => item.product.id == product.id);

    if (index >= 0) {
      _items[index].quantity += quantity;
      _atualizarNoFirestore(_items[index]);
    } else {
      final novoItem = CartItem(product: product, quantity: quantity);
      _items.add(novoItem);
      _atualizarNoFirestore(novoItem);
    }

    notifyListeners();
  }

  void removeSingleItem(String productId) {
    int index = _items.indexWhere((item) => item.product.id == productId);

    if (index >= 0) {
      if (_items[index].quantity > 1) {
        _items[index].quantity -= 1;
        _atualizarNoFirestore(_items[index]);
      } else {
        clearItem(productId);
      }

      notifyListeners();
    }
  }

  void clearItem(String productId) {
    _items.removeWhere((item) => item.product.id == productId);

    final user = _auth.currentUser;

    if (user != null) {
      _firestore
          .collection('usuarios')
          .doc(user.uid)
          .collection('carrinho')
          .doc(productId)
          .delete();
    }

    notifyListeners();
  }

  Future<void> _atualizarNoFirestore(CartItem item) async {
    final user = _auth.currentUser;
    if (user == null) return;

    await _firestore
        .collection('usuarios')
        .doc(user.uid)
        .collection('carrinho')
        .doc(item.product.id)
        .set(item.toMap()); // ✅ PADRONIZADO
  }

  void removeItem(String id) {
    clearItem(id);
  }
}
