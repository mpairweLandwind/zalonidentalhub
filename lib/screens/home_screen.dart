import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/screens/product_details.dart';
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
  int _currentIndex = 0;
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
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
                    _buildImageCarousel(productState.allProducts, productState.isLoading),
                    const SizedBox(height: 20),
                    _buildSwipeForMoreText(),
                    _buildCategorySection(title: "Categories", onViewAll: () {}),
                    _buildResponsiveCategoryList(productState.category, context),
                    const SizedBox(height: 20),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Most Popular",
                      content: _buildProductSection(productState.mostPopularProducts),
                      onViewAll: () {},
                    ),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Promotion",
                      content: _buildPromotionSection(productState.promotion),
                      onViewAll: () {},
                    ),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Latest",
                      content: _buildProductSection(productState.latestProducts),
                      onViewAll: () {},
                    ),
                    _buildSwipeForMoreText(),
                    _buildSection(
                      title: "Recommended",
                      content: _buildProductSection(productState.recommendedProducts),
                      onViewAll: () {},
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

  // Image Carousel Section with Tap Gesture
  Widget _buildImageCarousel(List<Product> allProducts, bool isLoading) {
    if (isLoading || allProducts.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Stack(
        alignment: Alignment.bottomCenter,
        children: [
          CarouselSlider.builder(
            itemCount: allProducts.length,
            itemBuilder: (context, index, realIndex) {
              final product = allProducts[index];
              return GestureDetector(
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
                child: ClipRRect(
                  borderRadius: BorderRadius.circular(10),
                  child: CachedNetworkImage(
                    imageUrl: product.imageUrl,
                    fit: BoxFit.cover,
                    width: double.infinity,
                    placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                    errorWidget: (context, url, error) => const Icon(Icons.error, size: 50, color: Colors.red),
                  ),
                ),
              );
            },
            options: CarouselOptions(
              viewportFraction: 1,
              height: MediaQuery.of(context).size.height * 0.25,
              autoPlay: true,
              onPageChanged: (index, reason) {
                setState(() => _currentIndex = index);
              },
            ),
          ),
          Positioned(
            bottom: 10,
            child: _buildIndicator(allProducts.length),
          ),
        ],
      ),
    );
  }
  // Carousel Indicator
  Widget _buildIndicator(int length) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(length, (index) {
        return GestureDetector(
          onTap: () {
            setState(() => _currentIndex = index);
          },
          child: Container(
            height: 10,
            width: 10,
            margin: const EdgeInsets.symmetric(horizontal: 4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _currentIndex == index ? const Color(0xFF146ABE) : const Color(0xFFEAEAEA),
            ),
          ),
        );
      }),
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

  // Responsive Category List
  Widget _buildResponsiveCategoryList(
    Map<String, Map<String, dynamic>> category, BuildContext context) {
  final screenWidth = MediaQuery.of(context).size.width;
  final itemWidth = (screenWidth - 48) / 4;

  return SizedBox(
    height: 120,
    child: ListView.builder(
      scrollDirection: Axis.horizontal,
      itemCount: category.length,
      itemBuilder: (context, index) {
        String categoryName = category.keys.elementAt(index);
        String imageUrl = category[categoryName]!['imageUrl'];
        List<String> subcategories = category[categoryName]!['subcategories'];
        List<Product> products = category[categoryName]!['products'];

        return GestureDetector(
          onTap: () {
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
          },
          child: Container(
            width: itemWidth,
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.grey[200],
              borderRadius: BorderRadius.circular(10),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Image.network(
                  imageUrl,
                  height: 60,
                  width: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) {
                    return const Icon(Icons.error, size: 50, color: Colors.red);
                  },
                ),
                const SizedBox(height: 5),
                Text(
                  categoryName,
                  style: const TextStyle(fontSize: 14),
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    ),
  );
}

  // Product Section with Tap Gesture
  Widget _buildProductSection(List<Product> products) {
    if (products.isEmpty) {
      return const Center(child: Text("No Products Available"));
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: products.length,
        itemBuilder: (context, index) {
          final product = products[index];
          return GestureDetector(
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
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        height: 120,
                        width: 150,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => const Center(child: CircularProgressIndicator()),
                        errorWidget: (context, url, error) => const Icon(Icons.error, size: 50, color: Colors.red),
                      ),
                      if (product.salePrice > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '${((1 - (product.salePrice / product.discountPrice)) * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                     _formatPrice(product.discountPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (product.salePrice > 0)
                    Text(
                       _formatPrice(product.salePrice),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  // Promotion Section
  Widget _buildPromotionSection(List<Product> promotions) {
    if (promotions.isEmpty) {
      return const Center(child: Text("No Promotions Available"));
    }

    return SizedBox(
      height: 200,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: promotions.length,
        itemBuilder: (context, index) {
          final product = promotions[index];
          return GestureDetector(
            onTap: () {
              Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (context) => ProductDetails(
                    key: ValueKey(product.name),
                    products: [product], categoryName: '', categoryImageUrl: '', subcategories: [],
                  ),
                ),
              );
            },
            child: Container(
              width: 150,
              margin: const EdgeInsets.only(left: 8),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(10),
                color: Colors.grey[200],
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Image.network(
                        product.imageUrl,
                        fit: BoxFit.cover,
                        height: 120,
                        width: 150,
                        errorBuilder: (context, error, stackTrace) {
                          return const Icon(Icons.error, size: 50, color: Colors.red);
                        },
                      ),
                      if (product.discountPrice > 0)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Text(
                              '-${((1 - (product.discountPrice / product.salePrice)) * 100).toStringAsFixed(1)}%',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    product.name,
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                  _formatPrice(product.discountPrice),
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.green,
                    ),
                  ),
                  if (product.salePrice > 0)
                    Text(
                      _formatPrice(product.salePrice),
                      style: const TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                    ),
                ],
              ),
            ),
          );
        },
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
