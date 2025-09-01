import 'dart:core';

class CartItem {
  final String name;
  final double salePrice;
  final double discountPrice;
  final double percentageReduction;
  final String imageUrl;
  int _quantity;

  CartItem({
    required this.name,    
    required this.salePrice,
    required this.discountPrice,
    required this.percentageReduction,
    required this.imageUrl,
    required int quantity,
  }) : _quantity = quantity;

  int get quantity => _quantity;

  set quantity(int newQuantity) {
    if (newQuantity >= 0) {
      _quantity = newQuantity;
    }
  }

  CartItem copyWith({
    String? name,
    double? salePrice,
    double? discountPrice,
    double? percentageReduction,
    String? imageUrl,
    int? quantity,
  }) {
    return CartItem(
      name: name ?? this.name,
      salePrice: salePrice ?? this.salePrice,
      discountPrice: discountPrice ?? this.discountPrice,
      percentageReduction: percentageReduction ?? this.percentageReduction,
      imageUrl: imageUrl ?? this.imageUrl,
      quantity: quantity ?? _quantity,
    );
  }
}