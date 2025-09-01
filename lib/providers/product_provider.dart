import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// Define the state class
class ProductState {
  final String? selectedCategory;
  final List<Product> products;
  final List<Product> promotion;
  final List<Product> allProducts;
  final List<Product> latestProducts;
  final List<Product> recommendedProducts;
  final List<Product> mostPopularProducts;
  final Map<String, Map<String, dynamic>>
      category; // Updated to store category data
  final bool isLoading;
  // Removed _precachedImages from ProductState
  ProductState({
    this.selectedCategory,
    this.products = const [],
    this.promotion = const [],
    this.allProducts = const [],
    this.latestProducts = const [],
    this.recommendedProducts = const [],
    this.mostPopularProducts = const [],
    this.category = const {},
    this.isLoading = false,
  });

  ProductState copyWith({
    String? selectedCategory,
    List<Product>? products,
    List<Product>? promotion,
    List<Product>? allProducts,
    List<Product>? latestProducts,
    List<Product>? recommendedProducts,
    List<Product>? mostPopularProducts,
    Map<String, Map<String, dynamic>>? category,
    bool? isLoading,
  }) {
    return ProductState(
      selectedCategory: selectedCategory ?? this.selectedCategory,
      products: products ?? this.products,
      promotion: promotion ?? this.promotion,
      allProducts: allProducts ?? this.allProducts,
      latestProducts: latestProducts ?? this.latestProducts,
      recommendedProducts: recommendedProducts ?? this.recommendedProducts,
      mostPopularProducts: mostPopularProducts ?? this.mostPopularProducts,
      category: category ?? this.category,
      isLoading: isLoading ?? this.isLoading,
    );
  }
}

// Define the notifier class
class ProductNotifier extends Notifier<ProductState> {
  final List<ImageProvider> _precachedImages =
      []; // Moved _precachedImages here

  @override
  ProductState build() => ProductState();

  void setSelectedCategory(String? category) {
    state = state.copyWith(selectedCategory: category);
    fetchProducts(category);
  }

  Future<void> fetchProducts(String? category) async {
    if (category == null) return;

    state = state.copyWith(isLoading: true);

    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('category', isEqualTo: category)
          .limit(10)
          .get();

      final products = querySnapshot.docs.map((doc) {
        var data = doc.data();

        return Product(
          category: data['category'] ?? '',
          subcategory: data['subcategory'] ?? '',
          name: data['name'] ?? '',
          quantity: data['quantity'] ?? 0,
          imageUrl: (data['imageUrls'] as List<dynamic>?)?.first ?? '',
          salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
          discountPrice: (data['discountPrice'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
        );
      }).toList();

      state = state.copyWith(
        products: products,
        allProducts: products, // Updated to use allProducts
        isLoading: false,
      ); // Precache images after products are loaded
      await precacheCarouselImages(products);
    } catch (error) {
      state = state.copyWith(isLoading: false);
    }
  }

// Add this method to precache images
  Future<void> precacheCarouselImages(List<Product> products) async {
    // Clear previous precached images
    for (final image in _precachedImages) {
      image.evict();
    }
    _precachedImages.clear();

    final imagesToPrecache = products
        .take(5) // Limit to 5 images for memory efficiency
        .map((product) => CachedNetworkImageProvider(product.imageUrl))
        .toList();

    for (final imageProvider in imagesToPrecache) {
      try {
        final image = imageProvider.resolve(ImageConfiguration.empty);
        if (!_precachedImages.contains(imageProvider)) {
          _precachedImages.add(imageProvider);
          image.addListener(ImageStreamListener((_, __) {}));
        }
      } catch (e) {
        // Handle image loading errors silently
      }
    }
  }

  Future<void> fetchCategory() async {
    try {
      var querySnapshot =
          await FirebaseFirestore.instance.collection('products').get();

      final category = <String, Map<String, dynamic>>{};
      for (var doc in querySnapshot.docs) {
        var data = doc.data();
        String categoryName = data['category'] ?? '';
        String imageUrl = (data['imageUrls'] as List<dynamic>?)?.first ?? '';
        String subcategory = data['subcategory'] ?? '';

        if (!category.containsKey(categoryName)) {
          category[categoryName] = {
            'imageUrl': imageUrl,
            'subcategories': <String>{subcategory},
            'products': <Product>[],
          };
        } else {
          // Add subcategory to the existing category
          category[categoryName]!['subcategories'].add(subcategory);
        }

        // Add product to the category
        category[categoryName]!['products'].add(Product(
          category: categoryName,
          subcategory: subcategory,
          name: data['name'] ?? '',
          quantity: data['quantity'] ?? 0,
          imageUrl: imageUrl,
          salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
          discountPrice: (data['discountPrice'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
        ));
      }

      // Convert subcategories from Set to List
      final updatedCategory = category.map((key, value) {
        return MapEntry(key, {
          'imageUrl': value['imageUrl'],
          'subcategories': value['subcategories'].toList(),
          'products': value['products'],
        });
      });

      state = state.copyWith(category: updatedCategory);
    } catch (error) {
      // Handle error
    }
  }

  Future<void> fetchPromotion() async {
    try {
      var querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('salePrice', isGreaterThan: 100000)
          .get();

      final promotion = querySnapshot.docs.map((doc) {
        var data = doc.data();
        return Product(
          category: data['category'] ?? '',
          subcategory: data['subcategory'] ?? '',
          name: data['name'] ?? '',
          quantity: data['quantity'] ?? 0,
          imageUrl: (data['imageUrls'] as List<dynamic>?)?.first ?? '',
          salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
          discountPrice: (data['discountPrice'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
        );
      }).toList();

      state = state.copyWith(promotion: promotion);
    } catch (error) {
      // No logging
    }
  }

  Future<void> fetchSpecialCategories() async {
    try {
      var latestQuerySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .orderBy('salePrice', descending: true)
          .limit(10)
          .get();

      final latestProducts = latestQuerySnapshot.docs.map((doc) {
        var data = doc.data();
        return Product(
          category: data['category'] ?? '',
          subcategory: data['subcategory'] ?? '',
          name: data['name'] ?? '',
          quantity: data['quantity'] ?? 0,
          imageUrl: (data['imageUrls'] as List<dynamic>?)?.first ?? '',
          salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
          discountPrice: (data['discountPrice'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
        );
      }).toList();

      // Fetch Most Popular Products by salePrice < 20000
      var popularQuerySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('salePrice', isLessThan: 20000) // Filter by salePrice < 20000
          .limit(10)
          .get();

      final mostPopularProducts = popularQuerySnapshot.docs.map((doc) {
        var data = doc.data();
        return Product(
          category: data['category'] ?? '',
          subcategory: data['subcategory'] ?? '',
          name: data['name'] ?? '',
          quantity: data['quantity'] ?? 0,
          imageUrl: (data['imageUrls'] as List<dynamic>?)?.first ?? '',
          salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
          discountPrice: (data['discountPrice'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
        );
      }).toList();

      // Fetch Recommended Products by salePrice > 200000
      var recommendedQuerySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('salePrice',
              isGreaterThan: 200000) // Filter by salePrice > 200000
          .limit(10)
          .get();

      final recommendedProducts = recommendedQuerySnapshot.docs.map((doc) {
        var data = doc.data();
        return Product(
          category: data['category'] ?? '',
          subcategory: data['subcategory'] ?? '',
          name: data['name'] ?? '',
          quantity: data['quantity'] ?? 0,
          imageUrl: (data['imageUrls'] as List<dynamic>?)?.first ?? '',
          salePrice: (data['salePrice'] as num?)?.toDouble() ?? 0.0,
          discountPrice: (data['discountPrice'] as num?)?.toDouble() ?? 0.0,
          description: data['description'] ?? '',
        );
      }).toList();

      state = state.copyWith(
        latestProducts: latestProducts,
        mostPopularProducts: mostPopularProducts,
        recommendedProducts: recommendedProducts,
      );
    } catch (error) {
      // No logging
    }
  }
}

// Define the provider
final productProvider =
    NotifierProvider<ProductNotifier, ProductState>(ProductNotifier.new);
