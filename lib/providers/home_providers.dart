import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../models/product.dart';

// ---------------------------------------------------------------------------
// Shared Firestore → Product helper
// ---------------------------------------------------------------------------
Product productFromFirestoreDoc(Map<String, dynamic> data) {
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

// ---------------------------------------------------------------------------
// 1. Categories — base data source (all products grouped by category)
// ---------------------------------------------------------------------------
final homeCategoriesProvider =
    FutureProvider<Map<String, Map<String, dynamic>>>((ref) async {
  final querySnapshot =
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
    category[categoryName]!['products'].add(productFromFirestoreDoc(data));
  }

  return category.map((key, value) => MapEntry(key, {
        'imageUrl': value['imageUrl'],
        'subcategories': (value['subcategories'] as Set<String>).toList(),
        'products': value['products'],
      }));
});

// ---------------------------------------------------------------------------
// 2. Carousel — derived from categories (2 per category, max 8)
// ---------------------------------------------------------------------------
final homeCarouselProvider = Provider<AsyncValue<List<Product>>>((ref) {
  return ref.watch(homeCategoriesProvider).whenData((categories) {
    final allProducts = <Product>[];
    for (final categoryData in categories.values) {
      final products = categoryData['products'] as List<Product>;
      allProducts.addAll(products.take(2));
    }
    return allProducts.take(8).toList();
  });
});

// ---------------------------------------------------------------------------
// 3. Most Popular — ordered by salesCount
// ---------------------------------------------------------------------------
final homePopularProvider = FutureProvider<List<Product>>((ref) async {
  QuerySnapshot<Map<String, dynamic>> snapshot;
  try {
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('salesCount', descending: true)
        .limit(10)
        .get();
  } catch (e) {
    debugPrint('Popular query fallback: $e');
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(10)
        .get();
  }
  if (snapshot.docs.isEmpty) {
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(10)
        .get();
  }
  return snapshot.docs
      .map((doc) => productFromFirestoreDoc(doc.data()))
      .toList();
});

// ---------------------------------------------------------------------------
// 4. Promotions — isPromotional flag with fallback
// ---------------------------------------------------------------------------
final homePromotionsProvider = FutureProvider<List<Product>>((ref) async {
  var snapshot = await FirebaseFirestore.instance
      .collection('products')
      .where('isPromotional', isEqualTo: true)
      .limit(20)
      .get();

  if (snapshot.docs.isEmpty) {
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .where('salePrice', isGreaterThan: 100000)
        .get();
  }
  return snapshot.docs
      .map((doc) => productFromFirestoreDoc(doc.data()))
      .toList();
});

// ---------------------------------------------------------------------------
// 5. Latest — ordered by createdAt
// ---------------------------------------------------------------------------
final homeLatestProvider = FutureProvider<List<Product>>((ref) async {
  QuerySnapshot<Map<String, dynamic>> snapshot;
  try {
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('createdAt', descending: true)
        .limit(10)
        .get();
  } catch (e) {
    debugPrint('Latest query fallback: $e');
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(10)
        .get();
  }
  if (snapshot.docs.isEmpty) {
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(10)
        .get();
  }
  return snapshot.docs
      .map((doc) => productFromFirestoreDoc(doc.data()))
      .toList();
});

// ---------------------------------------------------------------------------
// 6. Recommended — high salesCount + has discount
// ---------------------------------------------------------------------------
final homeRecommendedProvider = FutureProvider<List<Product>>((ref) async {
  QuerySnapshot<Map<String, dynamic>> snapshot;
  try {
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .orderBy('salesCount', descending: true)
        .limit(20)
        .get();
  } catch (e) {
    debugPrint('Recommended query fallback: $e');
    snapshot = await FirebaseFirestore.instance
        .collection('products')
        .limit(20)
        .get();
  }
  return snapshot.docs
      .map((doc) => productFromFirestoreDoc(doc.data()))
      .where((p) => p.discountPrice > 0 && p.discountPrice < p.salePrice)
      .take(10)
      .toList();
});

// ---------------------------------------------------------------------------
// 7. Search query — debounced via Notifier
// ---------------------------------------------------------------------------
class SearchQueryNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void update(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 300), () {
      state = query;
    });
  }

  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

final searchQueryProvider =
    NotifierProvider<SearchQueryNotifier, String>(SearchQueryNotifier.new);

// ---------------------------------------------------------------------------
// 8. Search results — derived from categories + debounced query
// ---------------------------------------------------------------------------
final homeSearchResultsProvider =
    Provider<AsyncValue<List<Product>>>((ref) {
  final query = ref.watch(searchQueryProvider).toLowerCase();
  if (query.isEmpty) return const AsyncData([]);

  return ref.watch(homeCategoriesProvider).whenData((categories) {
    final allProducts = <Product>[];
    for (final data in categories.values) {
      allProducts.addAll(data['products'] as List<Product>);
    }
    return allProducts
        .where((p) =>
            p.name.toLowerCase().contains(query) ||
            p.category.toLowerCase().contains(query))
        .toList();
  });
});
