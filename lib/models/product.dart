import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:hive/hive.dart';

part 'product.g.dart';

@HiveType(typeId: 1)
class Product extends HiveObject {
  @HiveField(0)
  final String id;
  @HiveField(1)
  final String name;
  @HiveField(2)
  final String description;
  @HiveField(3)
  final double price;
  @HiveField(4)
  final String imageUrl;
  @HiveField(5)
  final String categoryId;
  @HiveField(6)
  final int stock;
  @HiveField(7)
  final double rating;
  @HiveField(8)
  final int reviewCount;
  @HiveField(9)
  final bool isFeatured;
  @HiveField(10)
  final DateTime createdAt;
  @HiveField(11)
  final DateTime updatedAt;
  @HiveField(12)
  final String sellerId;
  @HiveField(13)
  final Map<String, String> caracteristicas;

  Product({
    required this.id,
    required this.name,
    required this.description,
    required this.price,
    required this.imageUrl,
    required this.categoryId,
    required this.stock,
    this.rating = 0.0,
    this.reviewCount = 0,
    this.isFeatured = false,
    required this.createdAt,
    required this.updatedAt,
    required this.sellerId,
    this.caracteristicas = const {},
  });

  // Método para crear un producto desde JSON
  factory Product.fromJson(Map<String, dynamic> json) {
    // Helper para parsear fechas sin importar si son Timestamp o String
    DateTime parseDate(dynamic dateValue) {
      if (dateValue is Timestamp) {
        return dateValue.toDate();
      }
      if (dateValue is String) {
        return DateTime.parse(dateValue);
      }
      // Si el valor es nulo o de un tipo inesperado, devuelve la fecha actual.
      return DateTime.now();
    }

    final createdAtDate = parseDate(json['createdAt']);
    // Si 'updatedAt' no existe o es nulo, usa 'createdAt' como valor por defecto.
    final updatedAtDate = json.containsKey('updatedAt') && json['updatedAt'] != null 
        ? parseDate(json['updatedAt']) 
        : createdAtDate;

    return Product(
      id: json['id'] as String,
      name: json['name'] as String,
      description: json['description'] as String,
      price: (json['price'] as num).toDouble(),
      imageUrl: json['imageUrl'] as String,
      categoryId: json['categoryId'] as String,
      stock: json['stock'] as int? ?? 0,
      rating: (json['rating'] as num?)?.toDouble() ?? 0.0,
      reviewCount: json['reviewCount'] as int? ?? 0,
      isFeatured: json['isFeatured'] as bool? ?? false,
      createdAt: createdAtDate,
      updatedAt: updatedAtDate,
      sellerId: json['sellerId'] as String? ?? '',
      caracteristicas: (json['caracteristicas'] as Map<String, dynamic>?)?.map((k, v) => MapEntry(k, v.toString())) ?? {},
    );
  }

  // Método para convertir el producto a JSON
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'price': price,
      'imageUrl': imageUrl,
      'categoryId': categoryId,
      'stock': stock,
      'rating': rating,
      'reviewCount': reviewCount,
      'isFeatured': isFeatured,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'sellerId': sellerId,
      'caracteristicas': caracteristicas,
    };
  }

  // Método para crear una copia del producto con algunos campos modificados
  Product copyWith({
    String? id,
    String? name,
    String? description,
    double? price,
    String? imageUrl,
    String? categoryId,
    int? stock,
    double? rating,
    int? reviewCount,
    bool? isFeatured,
    DateTime? createdAt,
    DateTime? updatedAt,
    String? sellerId,
    Map<String, String>? caracteristicas,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      price: price ?? this.price,
      imageUrl: imageUrl ?? this.imageUrl,
      categoryId: categoryId ?? this.categoryId,
      stock: stock ?? this.stock,
      rating: rating ?? this.rating,
      reviewCount: reviewCount ?? this.reviewCount,
      isFeatured: isFeatured ?? this.isFeatured,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      sellerId: sellerId ?? this.sellerId,
      caracteristicas: caracteristicas ?? this.caracteristicas,
    );
  }
} 