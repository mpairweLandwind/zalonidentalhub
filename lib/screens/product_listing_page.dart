import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../models/cart_icon_with_badge.dart';
import 'product_details.dart';

class ProductListingPage extends ConsumerStatefulWidget {
  final String title;
  final List<Product> products;
  final String categoryName;

  const ProductListingPage({
    super.key,
    required this.title,
    required this.products,
    this.categoryName = '',
  });

  @override
  ConsumerState<ProductListingPage> createState() => _ProductListingPageState();
}

class _ProductListingPageState extends ConsumerState<ProductListingPage> {
  final TextEditingController _searchController = TextEditingController();
  List<Product> _filteredProducts = [];
  List<Product> _displayedProducts = [];
  int _currentPage = 1;
  final int _itemsPerPage = 12;
  String _selectedSortOption = 'Default';
  String _selectedPriceFilter = 'All';
  bool _isGridView = true;

  final List<String> _sortOptions = [
    'Default',
    'Price: Low to High',
    'Price: High to Low',
    'Name: A-Z',
    'Name: Z-A',
    'Newest First',
  ];

  final List<String> _priceFilters = [
    'All',
    'Under UGX 50,000',
    'UGX 50,000 - 100,000',
    'UGX 100,000 - 200,000',
    'Above UGX 200,000',
  ];

  @override
  void initState() {
    super.initState();
    _filteredProducts = List.from(widget.products);
    _searchController.addListener(_onSearchChanged);
    _updateDisplayedProducts();
  }

  @override
  void dispose() {
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    super.dispose();
  }

  void _onSearchChanged() {
    final query = _searchController.text.toLowerCase();
    setState(() {
      if (query.isEmpty) {
        _filteredProducts = List.from(widget.products);
      } else {
        _filteredProducts = widget.products
            .where((product) =>
                product.name.toLowerCase().contains(query) ||
                product.category.toLowerCase().contains(query))
            .toList();
      }
      _currentPage = 1;
      _applySortingAndFiltering();
    });
  }

  void _applySortingAndFiltering() {
    List<Product> tempProducts = List.from(_filteredProducts);

    // Apply price filter
    if (_selectedPriceFilter != 'All') {
      tempProducts = tempProducts.where((product) {
        final price = product.discountPrice;
        switch (_selectedPriceFilter) {
          case 'Under UGX 50,000':
            return price < 50000;
          case 'UGX 50,000 - 100,000':
            return price >= 50000 && price <= 100000;
          case 'UGX 100,000 - 200,000':
            return price >= 100000 && price <= 200000;
          case 'Above UGX 200,000':
            return price > 200000;
          default:
            return true;
        }
      }).toList();
    }

    // Apply sorting
    switch (_selectedSortOption) {
      case 'Price: Low to High':
        tempProducts.sort((a, b) => a.discountPrice.compareTo(b.discountPrice));
        break;
      case 'Price: High to Low':
        tempProducts.sort((a, b) => b.discountPrice.compareTo(a.discountPrice));
        break;
      case 'Name: A-Z':
        tempProducts.sort((a, b) => a.name.compareTo(b.name));
        break;
      case 'Name: Z-A':
        tempProducts.sort((a, b) => b.name.compareTo(a.name));
        break;
      case 'Newest First':
        // Assuming newer products have higher IDs or you can add a date field
        tempProducts = tempProducts.reversed.toList();
        break;
      default:
        // Keep original order
        break;
    }

    setState(() {
      _filteredProducts = tempProducts;
      _updateDisplayedProducts();
    });
  }

  void _updateDisplayedProducts() {
    final startIndex = (_currentPage - 1) * _itemsPerPage;
    final endIndex = startIndex + _itemsPerPage;

    setState(() {
      _displayedProducts = _filteredProducts.length > startIndex
          ? _filteredProducts.sublist(
              startIndex,
              endIndex > _filteredProducts.length
                  ? _filteredProducts.length
                  : endIndex,
            )
          : [];
    });
  }

  int get _totalPages => (_filteredProducts.length / _itemsPerPage).ceil();

  String _formatPrice(double price) {
    return 'UGX ${price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          widget.title,
          style: const TextStyle(
            fontWeight: FontWeight.bold,
            fontSize: 20,
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black,
        elevation: 1,
        actions: [
          IconButton(
            icon: Icon(_isGridView ? Icons.view_list : Icons.grid_view),
            onPressed: () {
              setState(() {
                _isGridView = !_isGridView;
              });
            },
          ),
          const Padding(
            padding: EdgeInsets.only(right: 8.0),
            child: CartIconWithBadge(),
          ),
        ],
      ),
      body: Column(
        children: [
          _buildSearchAndFilterRow(),
          _buildResultsHeader(),
          Expanded(
            child: _displayedProducts.isEmpty
                ? _buildEmptyState()
                : _isGridView
                    ? _buildGridView()
                    : _buildListView(),
          ),
          if (_totalPages > 1) _buildPaginationControls(),
        ],
      ),
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Container(
      padding: const EdgeInsets.all(16),
      color: Colors.white,
      child: Column(
        children: [
          // Search bar
          TextField(
            controller: _searchController,
            decoration: InputDecoration(
              hintText: "Search products...",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: Colors.grey[300]!),
              ),
              prefixIcon: const Icon(Icons.search, color: Colors.grey),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            ),
          ),
          const SizedBox(height: 12),
          // Filter and Sort Row
          Row(
            children: [
              Expanded(
                child: _buildFilterDropdown(
                  'Sort by',
                  _selectedSortOption,
                  _sortOptions,
                  (value) {
                    setState(() {
                      _selectedSortOption = value!;
                      _applySortingAndFiltering();
                    });
                  },
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildFilterDropdown(
                  'Price Range',
                  _selectedPriceFilter,
                  _priceFilters,
                  (value) {
                    setState(() {
                      _selectedPriceFilter = value!;
                      _applySortingAndFiltering();
                    });
                  },
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFilterDropdown(
    String label,
    String selectedValue,
    List<String> options,
    ValueChanged<String?> onChanged,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: selectedValue,
          isExpanded: true,
          icon: const Icon(Icons.arrow_drop_down, size: 20),
          style: const TextStyle(fontSize: 14, color: Colors.black87),
          items: options.map((String option) {
            return DropdownMenuItem<String>(
              value: option,
              child: Text(
                option,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(fontSize: 14),
              ),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }

  Widget _buildResultsHeader() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      color: Colors.white,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            '${_filteredProducts.length} products found',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
              color: Colors.black87,
            ),
          ),
          if (_totalPages > 1)
            Text(
              'Page $_currentPage of $_totalPages',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildGridView() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: GridView.builder(
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2,
          childAspectRatio: 0.7,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
        ),
        itemCount: _displayedProducts.length,
        itemBuilder: (context, index) {
          return _buildProductGridCard(_displayedProducts[index]);
        },
      ),
    );
  }

  Widget _buildListView() {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: _displayedProducts.length,
      itemBuilder: (context, index) {
        return _buildProductListCard(_displayedProducts[index]);
      },
    );
  }

  Widget _buildProductGridCard(Product product) {
    final hasDiscount =
        product.salePrice > 0 && product.salePrice != product.discountPrice;
    final discountPercentage = hasDiscount
        ? ((1 - (product.discountPrice / product.salePrice)) * 100)
        : 0.0;

    return Material(
      borderRadius: BorderRadius.circular(12),
      elevation: 2,
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToProductDetails(product),
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
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
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
              ),
            ),
            Expanded(
              flex: 2,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        product.name,
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w500,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _formatPrice(product.discountPrice),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Color(0xFF2E7D32),
                        fontSize: 16,
                      ),
                    ),
                    if (hasDiscount)
                      Text(
                        _formatPrice(product.salePrice),
                        style: TextStyle(
                          decoration: TextDecoration.lineThrough,
                          color: Colors.grey[600],
                          fontSize: 12,
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

  Widget _buildProductListCard(Product product) {
    final hasDiscount =
        product.salePrice > 0 && product.salePrice != product.discountPrice;
    final discountPercentage = hasDiscount
        ? ((1 - (product.discountPrice / product.salePrice)) * 100)
        : 0.0;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: () => _navigateToProductDetails(product),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(
            children: [
              Stack(
                children: [
                  ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      width: 80,
                      height: 80,
                      fit: BoxFit.cover,
                      placeholder: (context, url) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Center(
                          child: CircularProgressIndicator(),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        width: 80,
                        height: 80,
                        color: Colors.grey[200],
                        child: const Icon(Icons.error),
                      ),
                    ),
                  ),
                  if (hasDiscount)
                    Positioned(
                      top: 4,
                      right: 4,
                      child: Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 4, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.orange,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${discountPercentage.toStringAsFixed(0)}%',
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
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      product.name,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 4),
                    Text(
                      product.category,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Text(
                          _formatPrice(product.discountPrice),
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Color(0xFF2E7D32),
                            fontSize: 18,
                          ),
                        ),
                        if (hasDiscount) ...[
                          const SizedBox(width: 8),
                          Text(
                            _formatPrice(product.salePrice),
                            style: TextStyle(
                              decoration: TextDecoration.lineThrough,
                              color: Colors.grey[600],
                              fontSize: 14,
                            ),
                          ),
                        ],
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
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
            'No products found',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Try adjusting your search or filters',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[500],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPaginationControls() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.1),
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          ElevatedButton.icon(
            onPressed: _currentPage > 1
                ? () {
                    setState(() {
                      _currentPage--;
                      _updateDisplayedProducts();
                    });
                  }
                : null,
            icon: const Icon(Icons.arrow_back_ios, size: 16),
            label: const Text('Previous'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
          Text(
            'Page $_currentPage of $_totalPages',
            style: const TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
          ),
          ElevatedButton.icon(
            onPressed: _currentPage < _totalPages
                ? () {
                    setState(() {
                      _currentPage++;
                      _updateDisplayedProducts();
                    });
                  }
                : null,
            icon: const Icon(Icons.arrow_forward_ios, size: 16),
            label: const Text('Next'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.blue,
              foregroundColor: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

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
}
