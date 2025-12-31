import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductRepository with ChangeNotifier {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal() {
    _startListening();
  }
  static ProductRepository get instance => _instance;

  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final String _collection = 'produtos';

  List<Product> _products = [];
  List<Product> get products => List.unmodifiable(_products);

  void _startListening() {
    _firestore.collection(_collection).snapshots().listen((snapshot) {
      _products = snapshot.docs.map((doc) {
        return Product.fromMap(doc.data(), doc.id);
      }).toList();
      notifyListeners();
    });
  }

  List<Product> getByCategory(String categoryName) {
    return _products.where((p) => p.category == categoryName).toList();
  }

  Future<void> addProduct(Product newProduct) async {
    try {
      await _firestore.collection(_collection).add(newProduct.toMap());
    } catch (e) {
      debugPrint("Erro ao adicionar produto: $e");
      rethrow;
    }
  }

  Future<void> updateProduct(Product updatedProduct) async {
    try {
      await _firestore
          .collection(_collection)
          .doc(updatedProduct.id)
          .update(updatedProduct.toMap());
    } catch (e) {
      debugPrint("Erro ao atualizar produto: $e");
      rethrow;
    }
  }

  Future<void> deleteProduct(String id) async {
    try {
      await _firestore.collection(_collection).doc(id).delete();
    } catch (e) {
      debugPrint("Erro ao excluir produto: $e");
      rethrow;
    }
  }
}
