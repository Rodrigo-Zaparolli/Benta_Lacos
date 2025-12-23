import 'dart:typed_data';

class Product {
  String id;
  final String name;
  final double price;
  final double? oldPrice;
  final String? imagePath; // principal (asset)
  final Uint8List? imageBytes; // principal (upload)
  final String? imageName;
  final List<Uint8List>? galleryImages; // 🔥 imagens secundárias
  final String description;
  final String color;
  final String composition;
  final String? category;

  Product({
    required this.id,
    required this.name,
    required this.price,
    this.oldPrice,
    this.imagePath,
    this.imageBytes,
    this.imageName,
    this.galleryImages,
    required this.description,
    required this.color,
    required this.composition,
    this.category,
  });

  Product copyWith({
    String? id,
    String? name,
    double? price,
    double? oldPrice,
    String? imagePath,
    Uint8List? imageBytes,
    String? imageName,
    List<Uint8List>? galleryImages,
    String? description,
    String? color,
    String? composition,
    String? category,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      oldPrice: oldPrice ?? this.oldPrice,
      imagePath: imagePath ?? this.imagePath,
      imageBytes: imageBytes ?? this.imageBytes,
      imageName: imageName ?? this.imageName,
      galleryImages: galleryImages ?? this.galleryImages,
      description: description ?? this.description,
      color: color ?? this.color,
      composition: composition ?? this.composition,
      category: category ?? this.category,
    );
  }
}
