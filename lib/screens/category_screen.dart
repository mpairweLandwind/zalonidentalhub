import 'dart:developer';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/models/product.dart';
import 'package:zalonidentalhub/screens/product_details.dart';
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
class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  @override
  Widget build(BuildContext context) {
    final productState = ref.watch(productProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Zaloni Dental Hub'),
        actions: const [CartIconWithBadge()],
      ),
      body: Row(
        children: [
          _buildSidebar(context, productState),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: productState.selectedCategory == null
                  ? _buildAllProducts(context, productState) // ✅ Default View
                  : _buildCategoryContent(context, productState), // ✅ Updates on Selection
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSidebar(BuildContext context, ProductState productState) {
    return Container(
      width: MediaQuery.of(context).size.width / 4,
      color: Colors.grey[100],
      child: ListView(
        padding: const EdgeInsets.all(8),
        children: [
          const Padding(
            padding: EdgeInsets.all(8.0),
            child: Text(
              'Categories',
              style: TextStyle(fontSize: 12),
            ),
          ),
          const Divider(),
          ...productState.category.keys.map((category) => _CategoryTile(
                category: category,
                isSelected: category == productState.selectedCategory,
                onTap: () {
                  ref.read(productProvider.notifier).setSelectedCategory(category);
                },
              )),
        ],
      ),
    );
  }


  
    Widget _buildAllProducts(BuildContext context, ProductState productState) {
    log('Building All Products');
    log('Total Categories: ${productState.category.length}');

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'All Products',
          style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: CustomScrollView(
            slivers: [
              ...productState.category.entries.map((entry) {
                final category = entry.key;
                final categoryData = entry.value;
                final productsInCategory = categoryData['products'] as List<Product>;
                final subcategories = _groupProductsBySubcategory(productsInCategory);

                log('Category: $category');
                log('Products in Category: ${productsInCategory.length}');
                log('Subcategories: ${subcategories.length}');

                return SliverList(
                  delegate: SliverChildListDelegate([
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 8.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            category,
                            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                          ),
                          TextButton(
                            onPressed: () {
                              ref.read(productProvider.notifier).setSelectedCategory(category);
                            },
                            child: const Text('See All', style: TextStyle(color: Colors.blue)),
                          ),
                        ],
                      ),
                    ),
                    ...subcategories.entries.map((entry) {
                      String subcategory = entry.key;
                      List<Product> products = entry.value;

                      log('Subcategory: $subcategory');
                      log('Products in Subcategory: ${products.length}');

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 8.0),
                            child: Text(
                              subcategory,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                            ),
                          ),
                          GridView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                              crossAxisCount: 3,
                              crossAxisSpacing: 16,
                              mainAxisSpacing: 16,
                              childAspectRatio: 0.8,
                            ),
                            itemCount: products.length,
                            itemBuilder: (context, index) {
                              var product = products[index];
                              return _buildProductCard(context, product);
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                      );
                    }),
                  ]),
                );
              }),
            ],
          ),
        ),
      ],
    );
  }
  
  
  
  
  Widget _buildProductCard(BuildContext context, Product product) {
  return Card(
    elevation: 4,
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
              products: [product], categoryName: '', categoryImageUrl: '', subcategories: [],
            ),
          ),
        );
      },
      child: Stack(
        children: [
          SingleChildScrollView(
            // Make the card scrollable
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                ClipRRect(
                  borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
                  child: Image.network(
                    product.imageUrl,
                    height: 150,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) => 
                        const Icon(Icons.broken_image, size: 50),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.normal,
                        ),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                             _formatPrice(product.discountPrice),
                            style: const TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                          if (product.discountPrice > 0)
                            Text(
                             _formatPrice(product.salePrice),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                                decoration: TextDecoration.lineThrough,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                        ],
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          
          // Price Reduction Percentage Badge
          if (product.discountPrice > 0)
            Positioned(
              top: 10,
              right: 10,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '-${((1 - (product.discountPrice / product.salePrice)) * 100).toStringAsFixed(1)}%',
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
  );
}

  Widget _buildCategoryContent(BuildContext context, ProductState productState) {
    final productsBySubcategory = _groupProductsBySubcategory(productState.products);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10.0),
          child: Text(
            productState.selectedCategory!,
            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
          ),
        ),
        const SizedBox(height: 16),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 10.0),
            itemCount: productsBySubcategory.length,
            itemBuilder: (context, index) {
              final subcategory = productsBySubcategory.keys.elementAt(index);
              final products = productsBySubcategory[subcategory]!;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: Text(
                      subcategory,
                      style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                    ),
                  ),
                  const SizedBox(height: 8),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 2,
                      crossAxisSpacing: 8,
                      mainAxisSpacing: 10,
                      childAspectRatio: 0.68,
                    ),
                    itemCount: products.length,
                    itemBuilder: (context, index) {
                      final product = products[index];
                      return _buildProductCard(context, product);
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

  Map<String, List<Product>> _groupProductsBySubcategory(List<Product> products) {
    final Map<String, List<Product>> productsBySubcategory = {};

    for (var product in products) {
      if (!productsBySubcategory.containsKey(product.subcategory)) {
        productsBySubcategory[product.subcategory] = [];
      }
      productsBySubcategory[product.subcategory]!.add(product);
    }

    return productsBySubcategory;
  }
}

class _CategoryTile extends StatelessWidget {
  final String category;
  final bool isSelected;
  final VoidCallback onTap;

  const _CategoryTile({
    required this.category,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
      tileColor: isSelected ? Colors.blue[50] : Colors.transparent,
      title: Text(
        category,
        style: TextStyle(
          fontSize: 14,
          fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          color: isSelected ? Colors.blue : Colors.black,
        ),
      ),
      onTap: onTap,
    );
  }
}
