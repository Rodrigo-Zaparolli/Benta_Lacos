import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../models/product_model.dart';

class CartItem {
  final Product product;
  int quantity;
  bool selecionado;

  CartItem({required this.product, this.quantity = 1, this.selecionado = true});
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

  /// NOVO MÉTODO: Remove apenas os itens que foram comprados (selecionados)
  /// Limpa tanto a lista local quanto o banco de dados Firestore
  Future<void> limparItensComprados() async {
    final user = _auth.currentUser;

    // Filtra apenas os itens que estavam marcados para compra
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
        // Executa a exclusão em massa no Firestore
        await batch.commit();
      } catch (e) {
        debugPrint("Erro ao limpar itens comprados no Firestore: $e");
      }
    }

    // Atualiza a lista local removendo apenas os comprados
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
        _items.add(
          CartItem(
            product: Product.fromMap(data['product'], doc.id),
            quantity: (data['quantity'] as num? ?? 1).toInt(),
            selecionado: data['selecionado'] as bool? ?? true,
          ),
        );
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
          _items.add(
            CartItem(
              product: Product.fromMap(data['product'], doc.id),
              quantity: (data['quantity'] as num? ?? 1).toInt(),
              selecionado: true,
            ),
          );
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

          batch.set(favRef, {
            'product': item.product.toMap(),
            'quantity': item.quantity,
            'data_movido': FieldValue.serverTimestamp(),
          });

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
        .set({
          'quantity': item.quantity,
          'selecionado': item.selecionado,
          'product': item.product.toMap(),
          'updatedAt': FieldValue.serverTimestamp(),
        });
  }

  void removeItem(String id) {
    clearItem(id);
  }
}
