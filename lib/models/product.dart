import 'package:cloud_firestore/cloud_firestore.dart';

class Product {
  final String? documentId; // Firestore doc ID for cursor-based pagination
  final String category;
  final String subcategory;
  final String name;
  final int quantity;
  final double salePrice;
  final double discountPrice;
  final String description;
  final String imageUrl;
  final DateTime? createdAt;
  final int salesCount;
  final bool isPromotional;

  const Product({
    this.documentId,
    required this.category,
    required this.subcategory,
    required this.name,
    required this.quantity,
    required this.salePrice,
    required this.discountPrice,
    required this.description,
    required this.imageUrl,
    this.createdAt,
    this.salesCount = 0,
    this.isPromotional = false,
  });

  // Derived attribute for percentage reduction
  double get percentageReduction {
    if (salePrice > 0 && discountPrice > 0) {
      return ((salePrice - discountPrice) / salePrice) * 100;
    } else {
      return 0.0;
    }
  }

  factory Product.fromMap(Map<String, dynamic> map, {String? documentId}) {
    return Product(
      documentId: documentId,
      category: (map['category'] as String?) ?? '',
      subcategory: (map['subcategory'] as String?) ?? '',
      name: (map['name'] as String?) ?? '',
      quantity: (map['quantity'] as int?) ?? 0,
      salePrice: (map['salePrice'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (map['discountPrice'] as num?)?.toDouble() ?? 0.0,
      description: (map['description'] as String?) ?? '',
      imageUrl: (map['imageUrl'] as String?) ?? '',
      createdAt: map['createdAt'] != null
          ? (map['createdAt'] as Timestamp).toDate()
          : null,
      salesCount: (map['salesCount'] as int?) ?? 0,
      isPromotional: (map['isPromotional'] as bool?) ?? false,
    );
  }

  /// Construct from a Firestore DocumentSnapshot, preserving doc ID for cursors.
  factory Product.fromDocument(DocumentSnapshot<Map<String, dynamic>> doc) {
    final data = doc.data()!;
    return Product(
      documentId: doc.id,
      category: data['category'] ?? '',
      subcategory: data['subcategory'] ?? '',
      name: data['name'] ?? '',
      quantity: data['quantity'] ?? 0,
      imageUrl: (data['imageUrls'] as List<dynamic>?)?.first ?? '',
      salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
      discountPrice: (data['discountPrice'] as num?)?.toDouble() ?? 0.0,
      description: data['description'] ?? '',
      createdAt: data['createdAt'] != null
          ? (data['createdAt'] as Timestamp).toDate()
          : null,
      salesCount: (data['salesCount'] as int?) ?? 0,
      isPromotional: (data['isPromotional'] as bool?) ?? false,
    );
  }
}
