import 'package:benta_lacos/core/config/store_environment.dart';
import 'dart:async';
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
  final FirebaseFirestore _firestore = StoreEnvironment.database;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  String? _ownerUid;
  Future<void>? _syncing;
  StreamSubscription<User?>? _authSubscription;

  CartProvider() {
    _authSubscription = _auth.authStateChanges().listen((user) {
      if (user != null) {
        sincronizarDoFirestore(user.uid);
      } else if (_ownerUid != null) {
        _ownerUid = null;
        clear();
      }
    });
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }

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
              .collection(StoreEnvironment.collectionName('usuarios'))
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

  Future<void> sincronizarDoFirestore(String uid) {
    return _syncing ??= _loadCart(uid).whenComplete(() => _syncing = null);
  }

  Future<void> _loadCart(String uid) async {
    try {
      final cartSnapshot = await _firestore
          .collection(StoreEnvironment.collectionName('usuarios'))
          .doc(uid)
          .collection('carrinho')
          .get();
      final favSnapshot = await _firestore
          .collection(StoreEnvironment.collectionName('usuarios'))
          .doc(uid)
          .collection('favoritos')
          .get();
      if (_auth.currentUser?.uid != uid) return;
      final merged = <String, CartItem>{};
      for (final doc in favSnapshot.docs) {
        merged[doc.id] = CartItem.fromMap(doc.data(), doc.id);
      }
      for (final doc in cartSnapshot.docs) {
        merged[doc.id] = CartItem.fromMap(doc.data(), doc.id);
      }
      if (_ownerUid == null) {
        for (final local in _items) {
          final remote = merged[local.product.id];
          merged[local.product.id] = CartItem(
            product: local.product,
            quantity: local.quantity + (remote?.quantity ?? 0),
            selecionado: local.selecionado,
          );
        }
      }
      _ownerUid = uid;
      _items.clear();
      _items.addAll(merged.values);
      notifyListeners();
      for (final item in _items.toList()) {
        await _atualizarNoFirestore(item);
      }
    } catch (error) {
      debugPrint(
        'Não foi possível sincronizar o carrinho: ' + error.toString(),
      );
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
              .collection(StoreEnvironment.collectionName('usuarios'))
              .doc(user.uid)
              .collection('favoritos')
              .doc(item.product.id);

          batch.set(favRef, item.toMap()); // ✅ MELHORADO

          final cartRef = _firestore
              .collection(StoreEnvironment.collectionName('usuarios'))
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
          .collection(StoreEnvironment.collectionName('usuarios'))
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
    try {
      await _firestore
          .collection(StoreEnvironment.collectionName('usuarios'))
          .doc(user.uid)
          .collection('carrinho')
          .doc(item.product.id)
          .set(item.toMap());
    } catch (error) {
      debugPrint('Não foi possível salvar o carrinho: ' + error.toString());
    }
  }

  void removeItem(String id) {
    clearItem(id);
  }
}
