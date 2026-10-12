import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String id;
  final bool isArchived;
  final DateTime? createdAt;
  final String name;
  final double price;
  final double? oldPrice;
  final String description;
  final String color;
  final String composition;
  final String? category;
  final String? imageUrl;
  final List<String>? galleryUrls;
  final double? discountPix;
  final bool isFeatured;
  final int views;
  final int quantity; // <-- NOVO CAMPO
  final bool madeToOrder;
  final int productionDays;
  final int orderCapacity;
  bool get available => madeToOrder ? orderCapacity > 0 : quantity > 0;
  int get purchaseLimit => madeToOrder ? orderCapacity : quantity;

  Product({
    required this.id,
    this.isArchived = false,
    this.createdAt,
    required this.name,
    required this.price,
    this.oldPrice,
    required this.description,
    required this.color,
    required this.composition,
    this.category,
    this.imageUrl,
    this.galleryUrls,
    this.discountPix,
    this.isFeatured = false,
    this.views = 0,
    this.quantity = 0, // inicializa com 0
    this.madeToOrder = false,
    this.productionDays = 7,
    this.orderCapacity = 10,
  });

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
      madeToOrder: map['madeToOrder'] == true,
      productionDays: (map['productionDays'] as num? ?? 7).toInt(),
      orderCapacity: (map['orderCapacity'] as num? ?? 10).toInt(),
      isArchived: map['isArchived'] == true,
      createdAt: map['createdAt'] is Timestamp
          ? (map['createdAt'] as Timestamp).toDate()
          : DateTime.tryParse(map['createdAt']?.toString() ?? ''),
      name: map['name'] ?? '',
      price: (map['price'] ?? 0).toDouble(),
      oldPrice: map['oldPrice']?.toDouble(),
      description: map['description'] ?? '',
      color: map['color'] ?? '',
      composition: map['composition'] ?? '',
      category: map['category'],
      imageUrl: map['imageUrl'],
      galleryUrls: map['galleryUrls'] != null
          ? List<String>.from(map['galleryUrls'])
          : null,
      discountPix: map['discountPix']?.toDouble(),
      isFeatured: map['isFeatured'] ?? false,
      views: map['views'] ?? 0,
      quantity: (map['quantity'] as num? ?? 0)
          .toInt(), // <-- mapeamento do novo campo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
      'madeToOrder': madeToOrder,
      'productionDays': productionDays,
      'orderCapacity': orderCapacity,
      'isArchived': isArchived,
      if (createdAt != null) 'createdAt': Timestamp.fromDate(createdAt!),
      'price': price,
      'oldPrice': oldPrice,
      'description': description,
      'color': color,
      'composition': composition,
      'category': category,
      'imageUrl': imageUrl,
      'galleryUrls': galleryUrls,
      'discountPix': discountPix,
      'isFeatured': isFeatured,
      'views': views,
      'quantity': quantity, // <-- salva no Firestore
    };
  }

  Product copyWith({
    String? id,
    bool? isArchived,
    DateTime? createdAt,
    String? name,
    double? price,
    double? oldPrice,
    String? description,
    String? color,
    String? composition,
    String? category,
    String? imageUrl,
    List<String>? galleryUrls,
    double? discountPix,
    bool? isFeatured,
    int? views,
    int? quantity, // <-- adiciona aqui
    bool? madeToOrder,
    int? productionDays,
    int? orderCapacity,
  }) {
    return Product(
      id: id ?? this.id,
      madeToOrder: madeToOrder ?? this.madeToOrder,
      productionDays: productionDays ?? this.productionDays,
      orderCapacity: orderCapacity ?? this.orderCapacity,
      isArchived: isArchived ?? this.isArchived,
      createdAt: createdAt ?? this.createdAt,
      name: name ?? this.name,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      description: description ?? this.description,
      color: color ?? this.color,
      composition: composition ?? this.composition,
      category: category ?? this.category,
      imageUrl: imageUrl ?? this.imageUrl,
      galleryUrls: galleryUrls ?? this.galleryUrls,
      discountPix: discountPix ?? this.discountPix,
      isFeatured: isFeatured ?? this.isFeatured,
      views: views ?? this.views,
      quantity: quantity ?? this.quantity, // <-- adiciona aqui
    );
  }
}
