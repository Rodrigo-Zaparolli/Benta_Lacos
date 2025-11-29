// lib/repository/product_repository.dart

import 'package:flutter/foundation.dart';
import '../models/product.dart';

class ProductRepository with ChangeNotifier {
  // Singleton
  static final ProductRepository _instance = ProductRepository._internal();
  factory ProductRepository() => _instance;
  ProductRepository._internal();
  static ProductRepository get instance => _instance;

  final List<Product> _products = [
    Product(
      id: 'p1',
      name: 'Laço Cerejinha',
      price: 19.90,
      oldPrice: 49.90,
      imagePath: 'assets/imagens/produtos/tiaras/tiaras.png',
      imageBytes: null,
      imageName: null,
      description:
          'Laço com aplique de cereja e opção de faixinha meia de seda.',
      color: 'Vermelha Cereja',
      composition: 'Faixa meia de seda: 100% algodão, Laço 100% poliéster.',
    ),
    Product(
      id: 'p2',
      name: 'Faixa Floral',
      price: 25.00,
      oldPrice: 35.00,
      imagePath: 'assets/imagens/produtos/faixas/faixa_floral.png',
      imageBytes: null,
      imageName: null,
      description: 'Faixa macia para recém-nascidos, estampa floral.',
      color: 'Rosa Floral',
      composition: 'Tecido: 80% Algodão, 20% Elastano.',
    ),
  ];

  List<Product> get products => List.unmodifiable(_products);

  // Criar novo produto com ID único
  void addProduct(Product newProduct) {
    final generatedId = DateTime.now().millisecondsSinceEpoch.toString();

    final productWithId = Product(
      id: generatedId,
      name: newProduct.name,
      price: newProduct.price,
      oldPrice: newProduct.oldPrice,
      imagePath: newProduct.imageBytes != null ? '' : newProduct.imagePath,
      imageBytes: newProduct.imageBytes,
      imageName: newProduct.imageName,
      description: newProduct.description,
      color: newProduct.color,
      composition: newProduct.composition,
    );

    _products.add(productWithId);
    notifyListeners();
  }

  void updateProduct(Product updatedProduct) {
    final idx = _products.indexWhere((p) => p.id == updatedProduct.id);
    if (idx != -1) {
      _products[idx] = updatedProduct;
      notifyListeners();
    }
  }

  void deleteProduct(String id) {
    _products.removeWhere((p) => p.id == id);
    notifyListeners();
  }

  Product? getById(String id) {
    try {
      return _products.firstWhere((p) => p.id == id);
    } catch (_) {
      return null;
    }
  }
}
