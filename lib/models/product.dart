class Product {
  final String id;
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

  Product({
    required this.id,
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
  });

  factory Product.fromMap(Map<String, dynamic> map, String docId) {
    return Product(
      id: docId,
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
      quantity: map['quantity'] ?? 0, // <-- mapeamento do novo campo
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'name': name,
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
  }) {
    return Product(
      id: id ?? this.id,
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
