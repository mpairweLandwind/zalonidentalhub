import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/product.dart';

// ---------------------------------------------------------------------------
// Constants
// ---------------------------------------------------------------------------
const int kPageSize = 20;

// ---------------------------------------------------------------------------
// 1. Category metadata — lightweight info for sidebar/drawer
// ---------------------------------------------------------------------------
class CategoryInfo {
  final String name;
  final String imageUrl;
  final List<String> subcategories;
  final int productCount;

  const CategoryInfo({
    required this.name,
    required this.imageUrl,
    required this.subcategories,
    required this.productCount,
  });
}

final categoryListProvider =
    FutureProvider<List<CategoryInfo>>((ref) async {
  final snapshot =
      await FirebaseFirestore.instance.collection('products').get();

  final categoryMap = <String, _CategoryAccumulator>{};
  for (final doc in snapshot.docs) {
    final data = doc.data();
    final name = data['category'] as String? ?? '';
    final imageUrl = (data['imageUrls'] as List<dynamic>?)?.first ?? '';
    final subcategory = data['subcategory'] as String? ?? '';

    categoryMap.putIfAbsent(
      name,
      () => _CategoryAccumulator(imageUrl: imageUrl),
    );
    categoryMap[name]!.subcategories.add(subcategory);
    categoryMap[name]!.productCount++;
  }

  return categoryMap.entries.map((e) {
    return CategoryInfo(
      name: e.key,
      imageUrl: e.value.imageUrl,
      subcategories: e.value.subcategories.toList(),
      productCount: e.value.productCount,
    );
  }).toList();
});

class _CategoryAccumulator {
  final String imageUrl;
  final Set<String> subcategories = {};
  int productCount = 0;
  _CategoryAccumulator({required this.imageUrl});
}

// ---------------------------------------------------------------------------
// 2. Selected category — Notifier-based
// ---------------------------------------------------------------------------
class SelectedCategoryNotifier extends Notifier<String?> {
  @override
  String? build() => null;

  void select(String? category) => state = category;
}

final selectedCategoryProvider =
    NotifierProvider<SelectedCategoryNotifier, String?>(
  SelectedCategoryNotifier.new,
);

// ---------------------------------------------------------------------------
// 3. View mode toggle — grid vs list
// ---------------------------------------------------------------------------
enum ProductViewMode { grid, list }

class ViewModeNotifier extends Notifier<ProductViewMode> {
  @override
  ProductViewMode build() => ProductViewMode.grid;

  void toggle() {
    state = state == ProductViewMode.grid
        ? ProductViewMode.list
        : ProductViewMode.grid;
  }
}

final productViewModeProvider =
    NotifierProvider<ViewModeNotifier, ProductViewMode>(ViewModeNotifier.new);

// ---------------------------------------------------------------------------
// 4. Paginated products — cursor-based Firestore pagination.
//    Reads selectedCategoryProvider reactively; resets on category change.
// ---------------------------------------------------------------------------
class PaginatedProductsState {
  final List<Product> products;
  final bool isLoading;
  final bool isLoadingMore;
  final bool hasMore;
  final int totalLoaded;
  final String? error;
  final DocumentSnapshot? lastDocument;

  const PaginatedProductsState({
    this.products = const [],
    this.isLoading = true,
    this.isLoadingMore = false,
    this.hasMore = true,
    this.totalLoaded = 0,
    this.error,
    this.lastDocument,
  });

  PaginatedProductsState copyWith({
    List<Product>? products,
    bool? isLoading,
    bool? isLoadingMore,
    bool? hasMore,
    int? totalLoaded,
    String? error,
    DocumentSnapshot? lastDocument,
    bool clearError = false,
    bool clearLastDoc = false,
  }) {
    return PaginatedProductsState(
      products: products ?? this.products,
      isLoading: isLoading ?? this.isLoading,
      isLoadingMore: isLoadingMore ?? this.isLoadingMore,
      hasMore: hasMore ?? this.hasMore,
      totalLoaded: totalLoaded ?? this.totalLoaded,
      error: clearError ? null : (error ?? this.error),
      lastDocument: clearLastDoc ? null : (lastDocument ?? this.lastDocument),
    );
  }
}

class PaginatedProductsNotifier extends Notifier<PaginatedProductsState> {
  @override
  PaginatedProductsState build() {
    // Watch selected category — rebuilds on category change
    final category = ref.watch(selectedCategoryProvider);
    _fetchFirstPage(category);
    return const PaginatedProductsState();
  }

  Future<void> _fetchFirstPage(String? category) async {
    try {
      final result = await _fetchPage(category: category, cursor: null);
      state = result.copyWith(isLoading: false);
    } catch (e) {
      debugPrint('Error fetching first page: $e');
      state = state.copyWith(
        isLoading: false,
        error: 'Failed to load products. Tap to retry.',
      );
    }
  }

  Future<PaginatedProductsState> _fetchPage({
    required String? category,
    required DocumentSnapshot? cursor,
    List<Product> existing = const [],
  }) async {
    Query<Map<String, dynamic>> query =
        FirebaseFirestore.instance.collection('products');

    if (category != null) {
      query = query.where('category', isEqualTo: category);
    }

    query = query.orderBy('name').limit(kPageSize);

    if (cursor != null) {
      query = query.startAfterDocument(cursor);
    }

    final snapshot = await query.get();
    final newProducts =
        snapshot.docs.map((doc) => Product.fromDocument(doc)).toList();

    final allProducts = [...existing, ...newProducts];

    return PaginatedProductsState(
      products: allProducts,
      isLoading: false,
      isLoadingMore: false,
      hasMore: snapshot.docs.length >= kPageSize,
      totalLoaded: allProducts.length,
      lastDocument: snapshot.docs.isNotEmpty ? snapshot.docs.last : cursor,
    );
  }

  /// Load next page (infinite scroll trigger).
  Future<void> loadMore() async {
    if (state.isLoadingMore || !state.hasMore || state.isLoading) return;

    state = state.copyWith(isLoadingMore: true, clearError: true);
    final category = ref.read(selectedCategoryProvider);

    try {
      final result = await _fetchPage(
        category: category,
        cursor: state.lastDocument,
        existing: state.products,
      );
      state = result;
    } catch (e) {
      debugPrint('Error loading more products: $e');
      state = state.copyWith(
        isLoadingMore: false,
        error: 'Failed to load more products.',
      );
    }
  }

  /// Pull-to-refresh — resets pagination from scratch.
  Future<void> refresh() async {
    state = const PaginatedProductsState();
    final category = ref.read(selectedCategoryProvider);
    await _fetchFirstPage(category);
  }
}

final paginatedProductsProvider =
    NotifierProvider<PaginatedProductsNotifier, PaginatedProductsState>(
  PaginatedProductsNotifier.new,
);

// ---------------------------------------------------------------------------
// 5. Search debounce for categories screen
// ---------------------------------------------------------------------------
class CategorySearchNotifier extends Notifier<String> {
  Timer? _debounce;

  @override
  String build() {
    ref.onDispose(() => _debounce?.cancel());
    return '';
  }

  void update(String query) {
    _debounce?.cancel();
    _debounce = Timer(const Duration(milliseconds: 400), () {
      state = query.trim();
    });
  }

  void clear() {
    _debounce?.cancel();
    state = '';
  }
}

final categorySearchProvider =
    NotifierProvider<CategorySearchNotifier, String>(
  CategorySearchNotifier.new,
);

// ---------------------------------------------------------------------------
// 6. Filtered products — derived from paginated + search query
// ---------------------------------------------------------------------------
final filteredCategoryProductsProvider =
    Provider<List<Product>>((ref) {
  final query = ref.watch(categorySearchProvider).toLowerCase();
  final paginated = ref.watch(paginatedProductsProvider);

  if (query.isEmpty) return paginated.products;

  return paginated.products.where((p) {
    return p.name.toLowerCase().contains(query) ||
        p.subcategory.toLowerCase().contains(query) ||
        p.category.toLowerCase().contains(query);
  }).toList();
});

// ---------------------------------------------------------------------------
// 7. Recent searches — stores last N search terms for suggestions
// ---------------------------------------------------------------------------
const int _kMaxRecentSearches = 8;

class RecentSearchesNotifier extends Notifier<List<String>> {
  @override
  List<String> build() => [];

  void add(String query) {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    // Remove duplicate, add to front, cap at max
    final updated = [trimmed, ...state.where((s) => s != trimmed)];
    state = updated.take(_kMaxRecentSearches).toList();
  }

  void remove(String query) {
    state = state.where((s) => s != query).toList();
  }

  void clearAll() => state = [];
}

final recentSearchesProvider =
    NotifierProvider<RecentSearchesNotifier, List<String>>(
  RecentSearchesNotifier.new,
);

// ---------------------------------------------------------------------------
// 8. Filtered categories list — applies search to category sidebar
// ---------------------------------------------------------------------------
final filteredCategoryListProvider =
    Provider<AsyncValue<List<CategoryInfo>>>((ref) {
  final query = ref.watch(categorySearchProvider).toLowerCase();
  final categoriesAsync = ref.watch(categoryListProvider);

  return categoriesAsync.whenData((categories) {
    if (query.isEmpty) return categories;
    return categories
        .where((c) => c.name.toLowerCase().contains(query))
        .toList();
  });
});
