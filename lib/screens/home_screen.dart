import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/screens/product_details.dart';
import 'package:zalonidentalhub/screens/product_listing_page.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../providers/product_provider.dart';
import '../models/product.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

// Helper function to format numbers with commas
String _formatPrice(double price) {
  return 'UGX ${price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  final CarouselSliderController _carouselController =
      CarouselSliderController();
  final ValueNotifier<int> _carouselIndexNotifier = ValueNotifier<int>(0);

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    // Initialize data when the widget is first created
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(productProvider.notifier).initializeAllData();
    });
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _carouselIndexNotifier.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    final productState = ref.read(productProvider);
    setState(() {
      _filteredProducts = productState.allProducts
          .where((product) =>
              product.name.toLowerCase().contains(query) ||
              product.category.toLowerCase().contains(query))
          .toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);
    //final screenWidth = MediaQuery.of(context).size.width;
    //final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: Colors.grey[100],
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildHeader(),
              const SizedBox(height: 20),
              _buildSearchFilterRow(),
              const SizedBox(height: 20),
              if (_searchController.text.isNotEmpty)
                _buildSearchResults(_filteredProducts)
              else
                Column(
                  children: [
                    _buildImageCarousel(
                        productState.allProducts, productState.isLoading),
                    const SizedBox(height: 20),
                    _buildSwipeForMoreText(),
                    _buildCategorySection(
                        title: "Categories",
                        onViewAll: () {
                          _navigateToAllCategories();
                        }),
                    _buildResponsiveCategoryList(
                        productState.category, context),
                    const SizedBox(height: 20),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Most Popular",
                      content: _buildProductSection(
                          productState.mostPopularProducts),
                      onViewAll: () {
                        _navigateToProductListing(
                          "Most Popular Products",
                          productState.mostPopularProducts,
                        );
                      },
                    ),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Promotion",
                      content: _buildPromotionSection(productState.promotion),
                      onViewAll: () {
                        _navigateToProductListing(
                          "Promotional Products",
                          productState.promotion,
                        );
                      },
                    ),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Latest",
                      content:
                          _buildProductSection(productState.latestProducts),
                      onViewAll: () {
                        _navigateToProductListing(
                          "Latest Products",
                          productState.latestProducts,
                        );
                      },
                    ),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Recommended",
                      content: _buildProductSection(
                          productState.recommendedProducts),
                      onViewAll: () {
                        _navigateToProductListing(
                          "Recommended Products",
                          productState.recommendedProducts,
                        );
                      },
                    ),
                  ],
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Search Results Section
  Widget _buildSearchResults(List<Product> products) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Search Results",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 10),
          _buildProductSection(products),
        ],
      ),
    );
  }

  // Header Section
  Widget _buildHeader() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                "Deliver To",
                style: TextStyle(fontSize: 16, color: Colors.black54),
              ),
              Row(
                children: const [
                  Icon(Icons.location_on, color: Colors.redAccent, size: 20),
                  Text(
                    "Kampala, Uganda",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Icon(Icons.arrow_drop_down, color: Colors.redAccent),
                ],
              ),
            ],
          ),
          IconButton(
            icon: const Icon(Icons.notifications, color: Colors.grey),
            onPressed: () {
              // Handle notification button press
            },
          ),
        ],
      ),
    );
  }

  // Search and Filter Row
  Widget _buildSearchFilterRow() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: "Search products...",
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                prefixIcon: const Icon(Icons.search, color: Colors.grey),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CartIconWithBadge(),
        ],
      ),
    );
  }

  // Optimized Image Carousel Section with Performance Improvements
  Widget _buildImageCarousel(List<Product> allProducts, bool isLoading) {
    if (isLoading || allProducts.isEmpty) {
      return _buildCarouselLoadingState();
    }

    // Limit carousel items for better performance
    final carouselProducts = allProducts.take(8).toList();

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          _buildOptimizedCarousel(carouselProducts),
          const SizedBox(height: 12),
          _buildCarouselIndicators(carouselProducts.length),
        ],
      ),
    );
  }

  // Optimized Carousel with better memory management
  Widget _buildOptimizedCarousel(List<Product> products) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      child: CarouselSlider.builder(
        carouselController: _carouselController,
        itemCount: products.length,
        itemBuilder: (context, index, realIndex) {
          final product = products[index];
          return _buildCarouselItem(product, index);
        },
        options: CarouselOptions(
          viewportFraction: 1.0,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          enlargeCenterPage: false,
          scrollDirection: Axis.horizontal,
          onPageChanged: (index, reason) {
            _carouselIndexNotifier.value = index;
          },
        ),
      ),
    );
  }

  // Optimized Carousel Item with lazy loading
  Widget _buildCarouselItem(Product product, int index) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToProductDetails(product),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Stack(
              fit: StackFit.expand,
              children: [
                _buildOptimizedImage(product.imageUrl),
                _buildCarouselOverlay(product),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Optimized image loading with better caching
  Widget _buildOptimizedImage(String imageUrl) {
    return CachedNetworkImage(
      imageUrl: imageUrl,
      fit: BoxFit.cover,
      memCacheHeight: 400, // Limit memory cache size
      memCacheWidth: 600,
      maxHeightDiskCache: 600,
      maxWidthDiskCache: 800,
      placeholder: (context, url) => _buildImagePlaceholder(),
      errorWidget: (context, url, error) => _buildImageError(),
      fadeInDuration: const Duration(milliseconds: 300),
      fadeOutDuration: const Duration(milliseconds: 100),
    );
  }

  // Optimized loading state
  Widget _buildCarouselLoadingState() {
    return Container(
      height: MediaQuery.of(context).size.height * 0.25,
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            SizedBox(
              width: 40,
              height: 40,
              child: CircularProgressIndicator(
                strokeWidth: 3,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              'Loading products...',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image placeholder for better UX
  Widget _buildImagePlaceholder() {
    return Container(
      color: Colors.grey[200],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.image,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Colors.grey[400]!,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Image error widget
  Widget _buildImageError() {
    return Container(
      color: Colors.grey[100],
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: Colors.grey[400],
            ),
            const SizedBox(height: 8),
            Text(
              'Image not available',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 12,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Carousel overlay with product info
  Widget _buildCarouselOverlay(Product product) {
    return Positioned(
      bottom: 0,
      left: 0,
      right: 0,
      child: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Colors.transparent,
              Colors.black.withValues(alpha: 0.7),
            ],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              product.name,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 16,
                fontWeight: FontWeight.bold,
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Text(
              _formatPrice(product.discountPrice),
              style: const TextStyle(
                color: Colors.white,
                fontSize: 14,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // Optimized carousel indicators using ValueListenableBuilder
  Widget _buildCarouselIndicators(int length) {
    return ValueListenableBuilder<int>(
      valueListenable: _carouselIndexNotifier,
      builder: (context, currentIndex, child) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (index) {
            final isActive = index == currentIndex;
            return GestureDetector(
              onTap: () {
                _carouselController.animateToPage(index);
                _carouselIndexNotifier.value = index;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8,
                width: isActive ? 24 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? const Color(0xFF146ABE)
                      : const Color(0xFFEAEAEA),
                ),
              ),
            );
          }),
        );
      },
    );
  }

  // Helper method for navigation
  void _navigateToProductDetails(Product product) {
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
  }

  // Helper method for product listing navigation
  void _navigateToProductListing(String title, List<Product> products) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductListingPage(
          title: title,
          products: products,
          categoryName: title,
        ),
      ),
    );
  }

  // Helper method for all categories navigation
  void _navigateToAllCategories() {
    final productState = ref.read(productProvider);
    final allProducts = <Product>[];

    // Collect all products from all categories
    productState.category.forEach((categoryName, categoryData) {
      final products = categoryData['products'] as List<Product>? ?? [];
      allProducts.addAll(products);
    });

    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductListingPage(
          title: "All Categories",
          products: allProducts,
          categoryName: "All Categories",
        ),
      ),
    );
  }

  // Section Builder
  Widget _buildSection({
    required String title,
    required Widget content,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 20),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold),
                ),
                GestureDetector(
                  onTap: () {
                    onViewAll();
                  },
                  child: const Text(
                    "View All",
                    style: TextStyle(color: Colors.redAccent, fontSize: 14),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          content,
        ],
      ),
    );
  }

  // Category Section
  Widget _buildCategorySection({
    required String title,
    required VoidCallback onViewAll,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            title,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          GestureDetector(
            onTap: () {
              onViewAll();
            },
            child: const Text(
              "View All",
              style: TextStyle(color: Colors.blue),
            ),
          ),
        ],
      ),
    );
  }

  // Optimized Responsive Category List
  Widget _buildResponsiveCategoryList(
      Map<String, Map<String, dynamic>> category, BuildContext context) {
    final screenWidth = MediaQuery.of(context).size.width;
    final itemWidth = (screenWidth - 48) / 4;

    return SizedBox(
      height: 120,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: category.length,
        cacheExtent: screenWidth * 2, // Cache items for smoother scrolling
        itemBuilder: (context, index) {
          String categoryName = category.keys.elementAt(index);
          String imageUrl = category[categoryName]!['imageUrl'];
          List<String> subcategories = category[categoryName]!['subcategories'];
          List<Product> products = category[categoryName]!['products'];

          return _buildCategoryItem(
            categoryName: categoryName,
            imageUrl: imageUrl,
            subcategories: subcategories,
            products: products,
            itemWidth: itemWidth,
          );
        },
      ),
    );
  }

  // Optimized Category Item
  Widget _buildCategoryItem({
    required String categoryName,
    required String imageUrl,
    required List<String> subcategories,
    required List<Product> products,
    required double itemWidth,
  }) {
    return Container(
      width: itemWidth,
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: Material(
        color: Colors.grey[200],
        borderRadius: BorderRadius.circular(12),
        elevation: 1,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToCategoryDetails(
            categoryName,
            imageUrl,
            subcategories,
            products,
          ),
          child: Padding(
            padding: const EdgeInsets.all(6),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Expanded(
                  flex: 3,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: imageUrl,
                      height: 50,
                      width: 50,
                      fit: BoxFit.cover,
                      memCacheHeight: 120,
                      memCacheWidth: 120,
                      placeholder: (context, url) => Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.category,
                          color: Colors.grey[400],
                          size: 25,
                        ),
                      ),
                      errorWidget: (context, error, stackTrace) => Container(
                        height: 50,
                        width: 50,
                        decoration: BoxDecoration(
                          color: Colors.grey[300],
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          Icons.error_outline,
                          color: Colors.grey[400],
                          size: 25,
                        ),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 4),
                Expanded(
                  flex: 2,
                  child: Text(
                    categoryName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // Helper method for category navigation
  void _navigateToCategoryDetails(
    String categoryName,
    String imageUrl,
    List<String> subcategories,
    List<Product> products,
  ) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => ProductDetails(
          key: ValueKey(categoryName),
          categoryName: categoryName,
          categoryImageUrl: imageUrl,
          subcategories: subcategories,
          products: products,
        ),
      ),
    );
  }

  // Optimized Product Section with better performance
  Widget _buildProductSection(List<Product> products) {
    if (products.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "No Products Available",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: products.length,
        cacheExtent: MediaQuery.of(context).size.width * 1.5,
        itemBuilder: (context, index) {
          final product = products[index];
          return _buildOptimizedProductCard(product);
        },
      ),
    );
  }

  // Optimized Product Card
  Widget _buildOptimizedProductCard(Product product) {
    final hasDiscount =
        product.salePrice > 0 && product.salePrice != product.discountPrice;
    final discountPercentage = hasDiscount
        ? ((1 - (product.discountPrice / product.salePrice)) * 100)
        : 0.0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 12, right: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () => _navigateToProductDetails(product),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildProductImage(product, discountPercentage, hasDiscount),
              _buildProductInfo(product, hasDiscount),
            ],
          ),
        ),
      ),
    );
  }

  // Optimized Product Image with overlay
  Widget _buildProductImage(
      Product product, double discountPercentage, bool hasDiscount) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: product.imageUrl,
            height: 130,
            width: 160,
            fit: BoxFit.cover,
            memCacheHeight: 260,
            memCacheWidth: 320,
            placeholder: (context, url) => Container(
              height: 130,
              width: 160,
              color: Colors.grey[200],
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      Theme.of(context).primaryColor,
                    ),
                  ),
                ),
              ),
            ),
            errorWidget: (context, url, error) => Container(
              height: 130,
              width: 160,
              color: Colors.grey[200],
              child: Icon(
                Icons.error_outline,
                color: Colors.grey[400],
                size: 40,
              ),
            ),
          ),
        ),
        if (hasDiscount)
          Positioned(
            top: 8,
            right: 8,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                '${discountPercentage.toStringAsFixed(0)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }

  // Product Information Section
  Widget _buildProductInfo(Product product, bool hasDiscount) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPrice(product.discountPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(height: 1),
                  Text(
                    _formatPrice(product.salePrice),
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Optimized Promotion Section
  Widget _buildPromotionSection(List<Product> promotions) {
    if (promotions.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32),
          child: Text(
            "No Promotions Available",
            style: TextStyle(
              color: Colors.grey,
              fontSize: 16,
            ),
          ),
        ),
      );
    }

    return SizedBox(
      height: 240,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: promotions.length,
        cacheExtent: MediaQuery.of(context).size.width * 1.5,
        itemBuilder: (context, index) {
          final product = promotions[index];
          return _buildPromotionCard(product);
        },
      ),
    );
  }

  // Optimized Promotion Card
  Widget _buildPromotionCard(Product product) {
    final hasDiscount =
        product.discountPrice > 0 && product.discountPrice != product.salePrice;
    final discountPercentage = hasDiscount
        ? ((1 - (product.discountPrice / product.salePrice)) * 100)
        : 0.0;

    return Container(
      width: 160,
      margin: const EdgeInsets.only(left: 12, right: 4),
      child: Material(
        borderRadius: BorderRadius.circular(12),
        elevation: 3,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            Navigator.of(context).push(
              MaterialPageRoute(
                builder: (context) => ProductDetails(
                  key: ValueKey(product.name),
                  products: [product],
                  categoryName: '',
                  categoryImageUrl: '',
                  subcategories: [],
                ),
              ),
            );
          },
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildPromotionImage(product),
                  _buildPromotionInfo(product, hasDiscount),
                ],
              ),
              // Promotion badge
              Positioned(
                top: 0,
                left: 0,
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    borderRadius: BorderRadius.only(
                      topLeft: Radius.circular(12),
                      bottomRight: Radius.circular(8),
                    ),
                  ),
                  child: const Text(
                    'PROMO',
                    style: TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 10,
                    ),
                  ),
                ),
              ),
              if (hasDiscount)
                Positioned(
                  top: 8,
                  right: 8,
                  child: Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
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
                        fontSize: 12,
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }

  // Promotion Image
  Widget _buildPromotionImage(Product product) {
    return ClipRRect(
      borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
      child: CachedNetworkImage(
        imageUrl: product.imageUrl,
        height: 130,
        width: 160,
        fit: BoxFit.cover,
        memCacheHeight: 260,
        memCacheWidth: 320,
        placeholder: (context, url) => Container(
          height: 130,
          width: 160,
          color: Colors.grey[200],
          child: Center(
            child: SizedBox(
              width: 24,
              height: 24,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                valueColor: AlwaysStoppedAnimation<Color>(
                  Theme.of(context).primaryColor,
                ),
              ),
            ),
          ),
        ),
        errorWidget: (context, url, error) => Container(
          height: 130,
          width: 160,
          color: Colors.grey[200],
          child: Icon(
            Icons.error_outline,
            color: Colors.grey[400],
            size: 40,
          ),
        ),
      ),
    );
  }

  // Promotion Information
  Widget _buildPromotionInfo(Product product, bool hasDiscount) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.all(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          mainAxisSize: MainAxisSize.min,
          children: [
            Flexible(
              child: Text(
                product.name,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  height: 1.1,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            const SizedBox(height: 1),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  _formatPrice(product.discountPrice),
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Color(0xFF2E7D32),
                    fontSize: 14,
                  ),
                ),
                if (hasDiscount) ...[
                  const SizedBox(height: 1),
                  Text(
                    _formatPrice(product.salePrice),
                    style: TextStyle(
                      decoration: TextDecoration.lineThrough,
                      color: Colors.grey[600],
                      fontSize: 11,
                    ),
                  ),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }

  // Swipe for More Text
  Widget _buildSwipeForMoreText() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(vertical: 10),
      color: Colors.blue,
      alignment: Alignment.center,
      child: const Text(
        "Swipe for More",
        style: TextStyle(
          fontSize: 14,
          color: Colors.white,
        ),
      ),
    );
  }
}
