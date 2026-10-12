import 'package:benta_lacos/core/config/store_environment.dart';
import '../services/admin_audit.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/product_model.dart';

class ProductRepository with ChangeNotifier {
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal() {
    _startListening();
  }
  static ProductRepository get instance => _instance;

  final FirebaseFirestore _firestore = StoreEnvironment.database;
  final String _collection = 'produtos';

  List<Product> _products = [];
  List<Product> get products =>
      List.unmodifiable(_products.where((p) => !p.isArchived));
  List<Product> get allProducts => List.unmodifiable(_products);

  StreamSubscription<QuerySnapshot<Map<String, dynamic>>>? _subscription;
  bool isLoading = true;
  String? error;

  void _startListening() {
    _subscription = _firestore
        .collection(_collection)
        .snapshots()
        .listen(
          (snapshot) {
            try {
              _products = snapshot.docs
                  .map((doc) => Product.fromMap(doc.data(), doc.id))
                  .toList();
              isLoading = false;
              error = null;
            } catch (_) {
              isLoading = false;
              error = 'Não foi possível ler o catálogo.';
            }
            notifyListeners();
          },
          onError: (Object exception) {
            isLoading = false;
            error = 'Não foi possível conectar ao catálogo.';
            notifyListeners();
          },
        );
  }

  Future<void> reload() async {
    await _subscription?.cancel();
    isLoading = true;
    error = null;
    notifyListeners();
    _startListening();
  }

  @override
  void dispose() {
    _subscription?.cancel();
    super.dispose();
  }

  List<Product> getByCategory(String categoryName) {
    return products.where((p) => p.category == categoryName).toList();
  }

  Future<void> addProduct(Product product) async {
    final ref = product.id.isEmpty
        ? _firestore.collection(_collection).doc()
        : _firestore.collection(_collection).doc(product.id);
    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(ref);
      if (current.exists) return;
      transaction.set(ref, {
        ...product.toMap(),
        'createdAt': FieldValue.serverTimestamp(),
        'updatedAt': FieldValue.serverTimestamp(),
        'historico': [auditEntry('Produto cadastrado')],
      });
    });
  }

  Future<void> updateProduct(Product product, {Product? original}) async {
    final ref = _firestore.collection(_collection).doc(product.id);
    await _firestore.runTransaction((transaction) async {
      final current = await transaction.get(ref);
      if (!current.exists) throw StateError('Produto não encontrado.');
      final data = current.data()!;
      final currentFields = Product.fromMap(data, product.id).toMap();
      final proposed = product.toMap();
      final before = original?.toMap();
      final patch = <String, dynamic>{};
      for (final key in proposed.keys) {
        if (['createdAt', 'views', 'isArchived'].contains(key)) continue;
        final old = before?[key];
        final next = proposed[key];
        final changed = before == null || !_equal(old, next);
        if (!changed) continue;
        if (before != null && !_equal(currentFields[key], old))
          throw StateError(
            'Este produto mudou em outra sessão. Reabra o formulário antes de salvar.',
          );
        patch[key] = next;
      }
      if (patch.isEmpty) return;
      transaction.update(ref, {
        ...patch,
        'updatedAt': FieldValue.serverTimestamp(),
        'historico': FieldValue.arrayUnion([
          auditEntry(
            'Produto atualizado',
            details: {
              'campos': patch.keys.toList(),
              if (patch.containsKey('quantity'))
                'estoqueAnterior': data['quantity'],
              if (patch.containsKey('quantity'))
                'estoqueNovo': patch['quantity'],
            },
          ),
        ]),
      });
    });
  }

  bool _equal(dynamic a, dynamic b) =>
      a is List && b is List ? listEquals(a, b) : a == b;

  Future<void> setArchived(String id, bool archived) async {
    await _firestore.collection(_collection).doc(id).update({
      'isArchived': archived,
      'updatedAt': FieldValue.serverTimestamp(),
      'historico': FieldValue.arrayUnion([
        auditEntry(archived ? 'Produto arquivado' : 'Produto restaurado'),
      ]),
    });
  }

  Future<void> adjustStock(
    String id,
    int quantity,
    String reason, {
    int? expectedQuantity,
  }) async {
    if (quantity < 0 || reason.trim().isEmpty)
      throw StateError('Informe uma quantidade válida e o motivo.');
    final ref = _firestore.collection(_collection).doc(id);
    await _firestore.runTransaction((transaction) async {
      final snapshot = await transaction.get(ref);
      if (!snapshot.exists) throw StateError('Produto não encontrado.');
      if (expectedQuantity != null &&
          (snapshot.data()?['quantity'] as num? ?? 0).toInt() !=
              expectedQuantity)
        throw StateError('O estoque mudou. Reabra o ajuste antes de salvar.');
      transaction.update(ref, {
        'quantity': quantity,
        'updatedAt': FieldValue.serverTimestamp(),
        'historico': FieldValue.arrayUnion([
          auditEntry(
            'Estoque ajustado',
            details: {
              'anterior': snapshot.data()?['quantity'],
              'novo': quantity,
              'motivo': reason.trim(),
            },
          ),
        ]),
      });
    });
  }

  // Compatibility: removal now archives the record and preserves order references.
  Future<void> deleteProduct(String id) => setArchived(id, true);
}
