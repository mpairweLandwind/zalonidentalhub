class Product {
  final String category;
  final String subcategory;
  final String name;
  final int quantity;
  final double salePrice;
  final double discountPrice;
  final String description;
  final String imageUrl;

  Product({
    required this.category,
    required this.subcategory,
    required this.name,
    required this.quantity,
    required this.salePrice,
    required this.discountPrice,
    required this.description,
    required this.imageUrl,
  });

  // Derived attribute for percentage reduction
  double get percentageReduction {
    if (salePrice > 0 && discountPrice > 0) {
      return ((salePrice - discountPrice) / salePrice) * 100;
    } else {
      return 0.0;
    }
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      category: map['category'] as String,
      subcategory: map['subcategory'] as String,
      name: map['name'] as String,
      quantity: map['quantity'] as int,
      salePrice: map['salePrice'] as double,
      discountPrice: map['discountPrice'] as double,
      description: map['description'] as String,
      imageUrl: map['imageUrl'] as String,
    );
  }
  
}
