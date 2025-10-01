import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
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

  // Initialize all data with optimized loading
  Future<void> initializeAllData() async {
    state = state.copyWith(isLoading: true);

    try {
      // Fetch data in parallel for better performance
      await Future.wait([
        fetchCategory(),
        fetchPromotion(),
        fetchSpecialCategories(),
      ]);

      // Use category data to populate allProducts for carousel
      final allProducts = <Product>[];
      for (final categoryData in state.category.values) {
        final products = categoryData['products'] as List<Product>;
        allProducts.addAll(products.take(2)); // Limit products per category
      }

      state = state.copyWith(
        allProducts: allProducts.take(8).toList(), // Limit carousel items
        isLoading: false,
      );

      // Precache carousel images after data loading
      if (allProducts.isNotEmpty) {
        await precacheCarouselImages(allProducts);
      }
    } catch (error) {
      state = state.copyWith(isLoading: false);
    }
  }

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

// Add this method to precache images with better memory management
  Future<void> precacheCarouselImages(List<Product> products) async {
    // Clear previous precached images to prevent memory leaks
    for (final image in _precachedImages) {
      image.evict();
    }
    _precachedImages.clear();

    // Limit to 8 images for optimal memory usage
    final imagesToPrecache = products
        .take(8)
        .where((product) => product.imageUrl.isNotEmpty)
        .map((product) => CachedNetworkImageProvider(product.imageUrl))
        .toList();

    // Precache images with error handling
    for (final imageProvider in imagesToPrecache) {
      try {
        if (!_precachedImages.contains(imageProvider)) {
          _precachedImages.add(imageProvider);

          // Precache with limited memory usage
          final imageStream = imageProvider.resolve(
            const ImageConfiguration(
              size: Size(400, 300), // Limit resolution for memory efficiency
            ),
          );

          // Add listener for preloading
          final completer = Completer<void>();
          late ImageStreamListener listener;

          listener = ImageStreamListener(
            (ImageInfo info, bool synchronousCall) {
              if (!completer.isCompleted) {
                completer.complete();
              }
              imageStream.removeListener(listener);
            },
            onError: (dynamic exception, StackTrace? stackTrace) {
              if (!completer.isCompleted) {
                completer.complete();
              }
              imageStream.removeListener(listener);
            },
          );

          imageStream.addListener(listener);

          // Wait for image to load with timeout
          await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              imageStream.removeListener(listener);
            },
          );
        }
      } catch (e) {
        // Silently handle preloading errors
        continue;
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
