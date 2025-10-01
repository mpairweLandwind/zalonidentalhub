import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/models/product.dart';
import 'package:zalonidentalhub/screens/product_details.dart';
import 'package:zalonidentalhub/screens/product_listing_page.dart';
import 'package:zalonidentalhub/providers/product_provider.dart';

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

// Helper function to format numbers with commas
String _formatPrice(double price) {
  return 'UGX ${price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with TickerProviderStateMixin {
  final TextEditingController _searchController = TextEditingController();
  String _searchQuery = '';
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(
      begin: 0.0,
      end: 1.0,
    ).animate(CurvedAnimation(
      parent: _animationController,
      curve: Curves.easeInOut,
    ));
    _animationController.forward();

    // Initialize data
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).initializeAllData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _animationController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    setState(() {
      _searchQuery = _searchController.text.toLowerCase();
    });
  }

  // Enhanced App Bar with better styling
  PreferredSizeWidget _buildAppBar(
      BuildContext context, ProductState productState) {
    return AppBar(
      title: const Text(
        'Categories',
        style: TextStyle(
          fontWeight: FontWeight.bold,
          fontSize: 22,
        ),
      ),
      backgroundColor: Colors.white,
      foregroundColor: Colors.black,
      elevation: 1,
      actions: [
        IconButton(
          icon: const Icon(Icons.grid_view),
          onPressed: () {
            // Toggle grid view
          },
        ),
        const Padding(
          padding: EdgeInsets.only(right: 8.0),
          child: CartIconWithBadge(),
        ),
      ],
    );
  }

  // Loading state with skeleton loading
  Widget _buildLoadingState() {
    return Row(
      children: [
        // Skeleton sidebar
        Container(
          width: MediaQuery.of(context).size.width * 0.28,
          color: Colors.grey[100],
          child: ListView.builder(
            itemCount: 8,
            itemBuilder: (context, index) {
              return Container(
                margin: const EdgeInsets.all(8),
                height: 40,
                decoration: BoxDecoration(
                  color: Colors.grey[300],
                  borderRadius: BorderRadius.circular(8),
                ),
              );
            },
          ),
        ),
        // Skeleton content
        Expanded(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Container(
                  height: 60,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: Colors.grey[300],
                    borderRadius: BorderRadius.circular(8),
                  ),
                ),
                const SizedBox(height: 16),
                Expanded(
                  child: GridView.builder(
                    gridDelegate:
                        const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 3,
                      crossAxisSpacing: 16,
                      mainAxisSpacing: 16,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: 12,
                    itemBuilder: (context, index) {
                      return Container(
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(12),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  // Search and breadcrumb navigation
  Widget _buildSearchAndBreadcrumb(
      BuildContext context, ProductState productState) {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search categories and products...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() {
                          _searchQuery = '';
                        });
                      },
                    )
                  : null,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Breadcrumb
          Row(
            children: [
              TextButton.icon(
                onPressed: () {
                  ref.read(productProvider.notifier).setSelectedCategory(null);
                },
                icon: const Icon(Icons.home, size: 16),
                label: const Text('All Categories'),
                style: TextButton.styleFrom(
                  foregroundColor: productState.selectedCategory == null
                      ? Colors.blue
                      : Colors.grey[600],
                ),
              ),
              if (productState.selectedCategory != null) ...[
                const Icon(Icons.chevron_right, color: Colors.grey),
                Expanded(
                  child: Text(
                    productState.selectedCategory!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w500,
                      color: Colors.blue,
                    ),
                    overflow: TextOverflow.ellipsis,
                    maxLines: 1,
                  ),
                ),
              ],
            ],
          ),
        ],
      ),
    );
  }

  // Enhanced sidebar with better styling
  Widget _buildEnhancedSidebar(
      BuildContext context, ProductState productState) {
    final categories = productState.category.keys.toList();
    final filteredCategories = _searchQuery.isEmpty
        ? categories
        : categories
            .where((category) => category.toLowerCase().contains(_searchQuery))
            .toList();

    return Container(
      width: MediaQuery.of(context).size.width * 0.28, // Slightly wider sidebar
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.05),
            blurRadius: 5,
            offset: const Offset(2, 0),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              border: Border(
                bottom: BorderSide(color: Colors.grey[200]!),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.category, color: Colors.blue[600], size: 18),
                const SizedBox(width: 6),
                const Expanded(
                  child: Text(
                    'Categories',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${filteredCategories.length}',
                    style: TextStyle(
                      color: Colors.blue[700],
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: ListView.builder(
              padding: const EdgeInsets.symmetric(vertical: 8),
              itemCount: filteredCategories.length,
              itemBuilder: (context, index) {
                final category = filteredCategories[index];
                final categoryData = productState.category[category];
                final productCount = categoryData?['products']?.length ?? 0;

                return _EnhancedCategoryTile(
                  category: category,
                  productCount: productCount,
                  isSelected: category == productState.selectedCategory,
                  onTap: () {
                    ref
                        .read(productProvider.notifier)
                        .setSelectedCategory(category);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  // Main content area
  Widget _buildMainContent(BuildContext context, ProductState productState) {
    return Container(
      color: Colors.grey[50],
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: productState.selectedCategory == null
            ? _buildEnhancedAllProducts(context, productState)
            : _buildEnhancedCategoryContent(context, productState),
      ),
    );
  }

  // Enhanced All Products view with better organization
  Widget _buildEnhancedAllProducts(
      BuildContext context, ProductState productState) {
    log('Building Enhanced All Products');

    final filteredProducts = _getFilteredProducts(productState);

    if (filteredProducts.isEmpty) {
      return _buildEmptyState('No products found matching your search');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          'All Products',
          '${filteredProducts.length} items',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListingPage(
                  title: 'All Products',
                  products: filteredProducts,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: GridView.builder(
            gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: _calculateCrossAxisCount(context),
              crossAxisSpacing: 16,
              mainAxisSpacing: 16,
              childAspectRatio: 0.8,
            ),
            itemCount: filteredProducts.take(12).length, // Show first 12 items
            itemBuilder: (context, index) {
              final product = filteredProducts[index];
              return _buildEnhancedProductCard(context, product);
            },
          ),
        ),
        if (filteredProducts.length > 12)
          Center(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: ElevatedButton.icon(
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => ProductListingPage(
                        title: 'All Products',
                        products: filteredProducts,
                      ),
                    ),
                  );
                },
                icon: const Icon(Icons.grid_view),
                label: Text('View All ${filteredProducts.length} Products'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  foregroundColor: Colors.white,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Enhanced Category Content view
  Widget _buildEnhancedCategoryContent(
      BuildContext context, ProductState productState) {
    final products = productState.products;
    final filteredProducts = _searchQuery.isEmpty
        ? products
        : products
            .where((product) =>
                product.name.toLowerCase().contains(_searchQuery) ||
                product.subcategory.toLowerCase().contains(_searchQuery))
            .toList();

    final productsBySubcategory = _groupProductsBySubcategory(filteredProducts);

    if (productsBySubcategory.isEmpty) {
      return _buildEmptyState('No products found in this category');
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _buildSectionHeader(
          productState.selectedCategory!,
          '${filteredProducts.length} items',
          () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ProductListingPage(
                  title: productState.selectedCategory!,
                  products: filteredProducts,
                ),
              ),
            );
          },
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            itemCount: productsBySubcategory.length,
            itemBuilder: (context, index) {
              final subcategory = productsBySubcategory.keys.elementAt(index);
              final products = productsBySubcategory[subcategory]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildSubcategoryHeader(subcategory, products.length),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: _calculateCrossAxisCount(context),
                      crossAxisSpacing: 12,
                      mainAxisSpacing: 12,
                      childAspectRatio: 0.8,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildEnhancedProductCard(context, product);
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            },
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);

    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: _buildAppBar(context, productState),
      body: productState.isLoading
          ? _buildLoadingState()
          : FadeTransition(
              opacity: _fadeAnimation,
              child: Column(
                children: [
                  _buildSearchAndBreadcrumb(context, productState),
                  Expanded(
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildEnhancedSidebar(context, productState),
                        Expanded(
                          child: _buildMainContent(context, productState),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
    );
  }

  Map<String, List<Product>> _groupProductsBySubcategory(
      List<Product> products) {
    final Map<String, List<Product>> productsBySubcategory = {};

    for (var product in products) {
      if (!productsBySubcategory.containsKey(product.subcategory)) {
        productsBySubcategory[product.subcategory] = [];
      }
      productsBySubcategory[product.subcategory]!.add(product);
    }

    return productsBySubcategory;
  }

  // Helper methods for enhanced UX

  List<Product> _getFilteredProducts(ProductState productState) {
    final allProducts = <Product>[];
    productState.category.forEach((categoryName, categoryData) {
      final products = categoryData['products'] as List<Product>? ?? [];
      allProducts.addAll(products);
    });

    if (_searchQuery.isEmpty) return allProducts;

    return allProducts
        .where((product) =>
            product.name.toLowerCase().contains(_searchQuery) ||
            product.category.toLowerCase().contains(_searchQuery) ||
            product.subcategory.toLowerCase().contains(_searchQuery))
        .toList();
  }

  int _calculateCrossAxisCount(BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    if (screenWidth > 1200) return 4;
    if (screenWidth > 800) return 3;
    return 2;
  }

  Widget _buildEmptyState(String message) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.search_off,
            size: 64,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search terms',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
      String title, String subtitle, VoidCallback onViewAll) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 13,
                  color: Colors.grey[600],
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        TextButton.icon(
          onPressed: onViewAll,
          icon: const Icon(Icons.arrow_forward, size: 16),
          label: const Text('View All'),
          style: TextButton.styleFrom(
            foregroundColor: Colors.blue,
          ),
        ),
      ],
    );
  }

  Widget _buildSubcategoryHeader(String subcategory, int productCount) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Row(
        children: [
          Icon(Icons.category_outlined, color: Colors.blue[700], size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              subcategory,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w600,
                color: Colors.blue[700],
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              '$productCount items',
              style: TextStyle(
                fontSize: 12,
                color: Colors.blue[700],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProductCard(BuildContext context, Product product) {
    final hasDiscount =
        product.salePrice > 0 && product.salePrice != product.discountPrice;
    final discountPercentage = hasDiscount
        ? ((1 - (product.discountPrice / product.salePrice)) * 100)
        : 0.0;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () {
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (context) => ProductDetails(
                key: ValueKey(product.name),
                products: [product],
                categoryName: product.category,
                categoryImageUrl: product.imageUrl,
                subcategories: [],
              ),
            ),
          );
        },
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Stack(
                children: [
                  ClipRRect(
                    borderRadius:
                        const BorderRadius.vertical(top: Radius.circular(12)),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: double.infinity,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        color: Colors.grey[200],
                        child: Center(
                          child: CircularProgressIndicator(
                            valueColor: AlwaysStoppedAnimation<Color>(
                                Colors.grey[400]!),
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey[400],
                        ),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 8,
                      right: 8,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 6, vertical: 4),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(8),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.2),
                              blurRadius: 4,
                              offset: const Offset(0, 2),
                            ),
                          ],
                        ),
                        child: Text(
                          '-${discountPercentage.toStringAsFixed(0)}%',
                          style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(4),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          height: 1.2,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Text(
                      _formatPrice(product.discountPrice),
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        height: 1.0,
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        _formatPrice(product.salePrice),
                        style: TextStyle(
                          fontSize: 9,
                          color: Colors.grey[600],
                          decoration: TextDecoration.lineThrough,
                          height: 1.0,
                        ),
                      ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Enhanced Category Tile Component
class _EnhancedCategoryTile extends StatelessWidget {
  final String category;
  final int productCount;
  final bool isSelected;
  final VoidCallback onTap;

  const _EnhancedCategoryTile({
    required this.category,
    required this.productCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      child: Material(
        color: isSelected ? Colors.blue[50] : Colors.transparent,
        borderRadius: BorderRadius.circular(8),
        child: InkWell(
          borderRadius: BorderRadius.circular(8),
          onTap: onTap,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
            decoration: BoxDecoration(
              border: Border.all(
                color: isSelected ? Colors.blue[300]! : Colors.transparent,
                width: 1,
              ),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: [
                Container(
                  width: 5,
                  height: 5,
                  decoration: BoxDecoration(
                    color: isSelected ? Colors.blue : Colors.grey[400],
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        category,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight:
                              isSelected ? FontWeight.w600 : FontWeight.normal,
                          color: isSelected ? Colors.blue[700] : Colors.black87,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '$productCount items',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.grey[600],
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Icon(
                    Icons.arrow_forward_ios,
                    size: 12,
                    color: Colors.blue[600],
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
