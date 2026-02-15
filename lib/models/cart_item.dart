class CartItem {
  final String name;
  final double salePrice;
  final double discountPrice;
  final double percentageReduction;
  final String imageUrl;
  final int quantity;

  const CartItem({
    required this.name,
    required this.salePrice,
    required this.discountPrice,
    required this.percentageReduction,
    required this.imageUrl,
    required this.quantity,
  });

  /// Line total at the discount price.
  double get lineTotal => discountPrice * quantity;

  /// How much the user saves on this line vs full sale price.
  double get lineSavings => (salePrice - discountPrice) * quantity;

  /// Whether there is an actual discount.
  bool get hasDiscount =>
      salePrice > 0 && discountPrice < salePrice;

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
      quantity: quantity ?? this.quantity,
    );
  }
}
