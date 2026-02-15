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
  final Map<String, Map<String, dynamic>> category;
  final bool isLoading;
  final String? errorMessage;
  final bool hasError;
  final bool isInitialized;

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
    this.errorMessage,
    this.hasError = false,
    this.isInitialized = false,
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
    String? errorMessage,
    bool? hasError,
    bool? isInitialized,
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
      errorMessage: errorMessage ?? this.errorMessage,
      hasError: hasError ?? this.hasError,
      isInitialized: isInitialized ?? this.isInitialized,
    );
  }
}

// Define the notifier class
class ProductNotifier extends Notifier<ProductState> {
  final List<ImageProvider> _precachedImages = [];

  @override
  ProductState build() => ProductState();

  /// Shared helper to construct a Product from a Firestore document map.
  Product _productFromDoc(Map<String, dynamic> data) {
    return Product(
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

  // Initialize all data with optimized loading
  Future<void> initializeAllData() async {
    // Guard: skip if already loaded successfully
    if (state.isInitialized && !state.hasError) return;

    state = state.copyWith(
      isLoading: true,
      hasError: false,
      errorMessage: null,
    );

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
        allProducts.addAll(products.take(2));
      }

      state = state.copyWith(
        allProducts: allProducts.take(8).toList(),
        isLoading: false,
        isInitialized: true,
      );

      // Precache carousel images after data loading
      if (allProducts.isNotEmpty) {
        await precacheCarouselImages(allProducts);
      }
    } catch (error) {
      debugPrint('Error initializing data: $error');
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load data. Pull down to retry.',
      );
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

      final products =
          querySnapshot.docs.map((doc) => _productFromDoc(doc.data())).toList();

      state = state.copyWith(
        products: products,
        allProducts: products,
        isLoading: false,
      );
      await precacheCarouselImages(products);
    } catch (error) {
      debugPrint('Error fetching products: $error');
      state = state.copyWith(
        isLoading: false,
        hasError: true,
        errorMessage: 'Failed to load products.',
      );
    }
  }

  // Precache images with better memory management
  Future<void> precacheCarouselImages(List<Product> products) async {
    for (final image in _precachedImages) {
      image.evict();
    }
    _precachedImages.clear();

    final imagesToPrecache = products
        .take(8)
        .where((product) => product.imageUrl.isNotEmpty)
        .map((product) => CachedNetworkImageProvider(product.imageUrl))
        .toList();

    for (final imageProvider in imagesToPrecache) {
      try {
        if (!_precachedImages.contains(imageProvider)) {
          _precachedImages.add(imageProvider);

          final imageStream = imageProvider.resolve(
            const ImageConfiguration(
              size: Size(400, 300),
            ),
          );

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

          await completer.future.timeout(
            const Duration(seconds: 5),
            onTimeout: () {
              imageStream.removeListener(listener);
            },
          );
        }
      } catch (e) {
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
          category[categoryName]!['subcategories'].add(subcategory);
        }

        category[categoryName]!['products'].add(_productFromDoc(data));
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
      debugPrint('Error fetching categories: $error');
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to load categories.',
      );
    }
  }

  Future<void> fetchPromotion() async {
    try {
      // Use isPromotional flag for proper promotion filtering
      var querySnapshot = await FirebaseFirestore.instance
          .collection('products')
          .where('isPromotional', isEqualTo: true)
          .limit(20)
          .get();

      // Fallback for old data without isPromotional field
      if (querySnapshot.docs.isEmpty) {
        querySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .where('salePrice', isGreaterThan: 100000)
            .get();
      }

      final promotion =
          querySnapshot.docs.map((doc) => _productFromDoc(doc.data())).toList();

      state = state.copyWith(promotion: promotion);
    } catch (error) {
      debugPrint('Error fetching promotions: $error');
    }
  }

  Future<void> fetchSpecialCategories() async {
    try {
      // LATEST: Order by createdAt (real recency)
      QuerySnapshot<Map<String, dynamic>> latestQuerySnapshot;
      try {
        latestQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .orderBy('createdAt', descending: true)
            .limit(10)
            .get();
      } catch (_) {
        // Fallback if createdAt field/index doesn't exist yet
        latestQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .limit(10)
            .get();
      }

      // If query succeeded but returned nothing, use fallback
      if (latestQuerySnapshot.docs.isEmpty) {
        latestQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .limit(10)
            .get();
      }

      final latestProducts = latestQuerySnapshot.docs
          .map((doc) => _productFromDoc(doc.data()))
          .toList();

      // MOST POPULAR: Order by salesCount (real popularity)
      QuerySnapshot<Map<String, dynamic>> popularQuerySnapshot;
      try {
        popularQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .orderBy('salesCount', descending: true)
            .limit(10)
            .get();
      } catch (_) {
        // Fallback if salesCount field/index doesn't exist yet
        popularQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .limit(10)
            .get();
      }

      if (popularQuerySnapshot.docs.isEmpty) {
        popularQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .limit(10)
            .get();
      }

      final mostPopularProducts = popularQuerySnapshot.docs
          .map((doc) => _productFromDoc(doc.data()))
          .toList();

      // RECOMMENDED: High sales + has a discount
      QuerySnapshot<Map<String, dynamic>> recommendedQuerySnapshot;
      try {
        recommendedQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .orderBy('salesCount', descending: true)
            .limit(20)
            .get();
      } catch (_) {
        recommendedQuerySnapshot = await FirebaseFirestore.instance
            .collection('products')
            .limit(20)
            .get();
      }

      final recommendedProducts = recommendedQuerySnapshot.docs
          .map((doc) => _productFromDoc(doc.data()))
          .where(
              (p) => p.discountPrice > 0 && p.discountPrice < p.salePrice)
          .take(10)
          .toList();

      state = state.copyWith(
        latestProducts: latestProducts,
        mostPopularProducts: mostPopularProducts,
        recommendedProducts: recommendedProducts,
      );
    } catch (error) {
      debugPrint('Error fetching special categories: $error');
      state = state.copyWith(
        hasError: true,
        errorMessage: 'Failed to load product sections.',
      );
    }
  }
}

// Define the provider
final productProvider =
    NotifierProvider<ProductNotifier, ProductState>(ProductNotifier.new);
