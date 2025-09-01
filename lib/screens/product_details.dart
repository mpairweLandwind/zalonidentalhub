import 'package:flutter/material.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/models/cart_item.dart';
import 'package:zalonidentalhub/models/cart_model.dart';
import 'package:zalonidentalhub/models/product.dart';

class ProductDetails extends ConsumerWidget {
  final String categoryName;
  final String categoryImageUrl;
  final List<String> subcategories;
  final List<Product> products;

  const ProductDetails({
    required Key key,
    required this.categoryName,
    required this.categoryImageUrl,
    required this.subcategories,
    required this.products,
  }) : super(key: key);
    // Helper function to format numbers with commas
  String _formatPrice(double price) {
    return 'UGX ${price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    if (products.isEmpty) {
      return const Center(child: Text("No products available."));
    }

    // Group products by subcategory
    final Map<String, List<Product>> groupedProducts = {};
    for (var product in products) {
      if (!groupedProducts.containsKey(product.subcategory)) {
        groupedProducts[product.subcategory] = [];
      }
      groupedProducts[product.subcategory]!.add(product);
    }

    final List<String> subcategories = groupedProducts.keys.toList();

    return DefaultTabController(
      length: subcategories.length,
      child: Scaffold(
        appBar: AppBar(
          title: Text(categoryName), // Display category name
          actions: _buildAppBarActions(ref),
          bottom: TabBar(
            isScrollable: true, // Allow horizontal scrolling for many subcategories
            tabs: subcategories.map((subcategory) {
              return Tab(text: subcategory);
            }).toList(),
          ),
        ),
        body: TabBarView(
          children: subcategories.map((subcategory) {
            return _buildProductLayout(context, ref, groupedProducts[subcategory]!);
          }).toList(),
        ),
      ),
    );
  }

  List<Widget> _buildAppBarActions(WidgetRef ref) {
    return [
      IconButton(
        icon: const Icon(Icons.search),
        onPressed: () {
          // Implement search functionality
        },
      ),
      const CartIconWithBadge(),
    ];
  }

  Widget _buildProductLayout(BuildContext context, WidgetRef ref, List<Product> products) {
    if (products.length == 1) {
      // Single product occupies full width
      return _buildSingleProductCard(context, ref, products.first);
    } else {
      // Multiple products use a 2-column grid
      return _buildProductGrid(context, products);
    }
  }

  Widget _buildSingleProductCard(BuildContext context, WidgetRef ref, Product product) {
    // Calculate percentage reduction to 1 decimal place
    double percentageReduction = 0;
    if (product.salePrice > 0 && product.discountPrice < product.salePrice) {
      percentageReduction = (1 - (product.discountPrice / product.salePrice)) * 100;
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Enhanced Image Section with Carousel for Multiple Images
          _buildImageSection(product, percentageReduction),
          const SizedBox(height: 16),
          Text(
            product.name,
            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              if (product.salePrice != product.discountPrice)
                Text(
                     _formatPrice(product.salePrice),
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        decoration: TextDecoration.lineThrough,
                        color: Colors.grey,
                      ),
                ),
              const SizedBox(width: 8),
              Text(
               _formatPrice(product.discountPrice),
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                      color: Colors.black,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          _buildRatingBar(4.5), // Assuming you pass the actual rating
          const SizedBox(height: 16),
          Text(
            product.description,
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity, // Make button take maximum width
            child: ElevatedButton(
              onPressed: () {
                ref.read(cartProvider.notifier).addToCart(
                  CartItem(
                    name: product.name,
                    salePrice: product.salePrice,
                    discountPrice: product.discountPrice,
                    percentageReduction: percentageReduction,
                    imageUrl: product.imageUrl,
                    quantity: 1,
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Product added to cart!'),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                foregroundColor: Colors.white,
                backgroundColor: Theme.of(context).primaryColor,
                padding: const EdgeInsets.symmetric(vertical: 16),
              ),
              child: const Text('Add to Cart'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImageSection(Product product, double percentageReduction) {
    // Assuming product has a list of image URLs
    List<String> imageUrls = [product.imageUrl, product.imageUrl, product.imageUrl]; // Replace with actual image URLs

    // Create a PageController for the carousel
    final PageController pageController = PageController();

    return Stack(
      children: [
        AspectRatio(
          aspectRatio: 1,
          child: PageView.builder(
            controller: pageController,
            itemCount: imageUrls.length,
            itemBuilder: (context, index) {
              return ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Image.network(
                  imageUrls[index],
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) =>
                      const Icon(Icons.error, size: 50, color: Colors.red),
                ),
              );
            },
          ),
        ),
        // Left Arrow
        if (imageUrls.length > 1)
          Positioned(
            left: 8,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios, color: Colors.white),
              onPressed: () {
                pageController.previousPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        // Right Arrow
        if (imageUrls.length > 1)
          Positioned(
            right: 8,
            top: 0,
            bottom: 0,
            child: IconButton(
              icon: const Icon(Icons.arrow_forward_ios, color: Colors.white),
              onPressed: () {
                pageController.nextPage(
                  duration: const Duration(milliseconds: 300),
                  curve: Curves.easeInOut,
                );
              },
            ),
          ),
        // Discount Percentage Badge
        if (percentageReduction > 0)
          Positioned(
            top: 16,
            right: 16,
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.orange,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '-${percentageReduction.toStringAsFixed(1)}%',
                style: const TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildProductGrid(BuildContext context, List<Product> products) {
    return GridView.builder(
      padding: const EdgeInsets.all(16),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, // 2-column grid
        crossAxisSpacing: 16,
        mainAxisSpacing: 16,
        childAspectRatio: 0.75, // Adjust aspect ratio for better layout
      ),
      itemCount: products.length,
      itemBuilder: (context, index) {
        return _buildProductCard(context, products[index]);
      },
    );
  }

  Widget _buildProductCard(BuildContext context, Product product) {
    // Calculate percentage reduction to 1 decimal place
    double percentageReduction = 0;
    if (product.salePrice > 0 && product.discountPrice < product.salePrice) {
      percentageReduction = (1 - (product.discountPrice / product.salePrice)) * 100;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: InkWell(
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
        borderRadius: BorderRadius.circular(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Enhanced Image Section with Carousel for Multiple Images
            _buildImageSection(product, percentageReduction),
            // Scrollable Bottom Section
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Name
                    Text(
                      product.name,
                      style: Theme.of(context).textTheme.titleMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),

                    // Discount Price Above Sale Price
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          _formatPrice(product.discountPrice),
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontWeight: FontWeight.bold,
                                color: Colors.black,
                              ),
                        ),
                        if (product.salePrice != product.discountPrice)
                          Text(
                              _formatPrice(product.salePrice),
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  decoration: TextDecoration.lineThrough,
                                  color: Colors.grey,
                                ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),

                    // Rating Bar
                    _buildRatingBar(3.5), // Assuming you pass the actual rating
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingBar(double rating) {
    return RatingBarIndicator(
      rating: rating,
      itemBuilder: (context, index) => const Icon(
        Icons.star,
        color: Colors.amber,
      ),
      itemCount: 5,
      itemSize: 16.0,
      direction: Axis.horizontal,
    );
  }
}
