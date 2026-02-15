import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:carousel_slider/carousel_slider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/screens/product_details.dart';
import 'package:zalonidentalhub/screens/product_listing_page.dart';
import 'package:zalonidentalhub/theme/app_theme.dart';
import 'package:zalonidentalhub/widgets/shimmer_loading.dart';
import '../providers/home_providers.dart';
import '../models/product.dart';

// ═══════════════════════════════════════════════════════════════════════════
// Price formatter
// ═══════════════════════════════════════════════════════════════════════════
String _formatPrice(double price) {
  return 'UGX ${price.toStringAsFixed(2).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

// ═══════════════════════════════════════════════════════════════════════════
// HomeScreen — root widget
// ═══════════════════════════════════════════════════════════════════════════
class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});
  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  final TextEditingController _searchController = TextEditingController();
  bool _isSearchActive = false;

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
    final isActive = _searchController.text.isNotEmpty;
    if (_isSearchActive != isActive) {
      setState(() => _isSearchActive = isActive);
    }
    ref.read(searchQueryProvider.notifier).update(_searchController.text);
  }

  Future<void> _onRefresh() async {
    ref.invalidate(homeCategoriesProvider);
    ref.invalidate(homePopularProvider);
    ref.invalidate(homePromotionsProvider);
    ref.invalidate(homeLatestProvider);
    ref.invalidate(homeRecommendedProvider);
    await Future.wait([
      ref.read(homeCategoriesProvider.future),
      ref.read(homePopularProvider.future),
      ref.read(homePromotionsProvider.future),
      ref.read(homeLatestProvider.future),
      ref.read(homeRecommendedProvider.future),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surfaceContainerLowest,
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: _onRefresh,
          child: CustomScrollView(
            physics: const AlwaysScrollableScrollPhysics(
              parent: BouncingScrollPhysics(),
            ),
            slivers: [
              const SliverToBoxAdapter(child: _HomeHeader()),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              SliverToBoxAdapter(
                child: _SearchBar(controller: _searchController),
              ),
              const SliverToBoxAdapter(child: SizedBox(height: 20)),
              if (_isSearchActive)
                const SliverToBoxAdapter(child: _SearchResultsSection())
              else ...[
                const SliverToBoxAdapter(child: _CarouselSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                const SliverToBoxAdapter(child: _CategoriesSection()),
                const SliverToBoxAdapter(child: SizedBox(height: 20)),
                SliverToBoxAdapter(
                  child: _HomeProductSection(
                    provider: homePopularProvider,
                    title: 'Most Popular',
                  ),
                ),
                const SliverToBoxAdapter(child: _HomePromotionsSection()),
                SliverToBoxAdapter(
                  child: _HomeProductSection(
                    provider: homeLatestProvider,
                    title: 'Latest',
                  ),
                ),
                SliverToBoxAdapter(
                  child: _HomeProductSection(
                    provider: homeRecommendedProvider,
                    title: 'Recommended',
                  ),
                ),
              ],
              const SliverToBoxAdapter(child: SizedBox(height: 24)),
            ],
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Header — delivery location + notification
// ═══════════════════════════════════════════════════════════════════════════
class _HomeHeader extends StatelessWidget {
  const _HomeHeader();

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Deliver To',
                  style:
                      TextStyle(fontSize: 16, color: cs.onSurfaceVariant)),
              Row(
                children: [
                  Icon(Icons.location_on, color: cs.error, size: 20),
                  const Text('Kampala, Uganda',
                      style: TextStyle(
                          fontSize: 18, fontWeight: FontWeight.bold)),
                  Icon(Icons.arrow_drop_down, color: cs.error),
                ],
              ),
            ],
          ),
          IconButton(
            icon: Icon(Icons.notifications, color: cs.onSurfaceVariant),
            onPressed: () {},
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Search bar + cart icon
// ═══════════════════════════════════════════════════════════════════════════
class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              decoration: InputDecoration(
                hintText: 'Search products...',
                border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12)),
                prefixIcon: Icon(Icons.search,
                    color: Theme.of(context).colorScheme.onSurfaceVariant),
              ),
            ),
          ),
          const SizedBox(width: 8),
          const CartIconWithBadge(),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Carousel — watches homeCarouselProvider (derived from categories)
// ═══════════════════════════════════════════════════════════════════════════
class _CarouselSection extends ConsumerStatefulWidget {
  const _CarouselSection();
  @override
  ConsumerState<_CarouselSection> createState() => _CarouselSectionState();
}

class _CarouselSectionState extends ConsumerState<_CarouselSection> {
  final _controller = CarouselSliderController();
  final _indexNotifier = ValueNotifier<int>(0);

  @override
  void dispose() {
    _indexNotifier.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final carouselAsync = ref.watch(homeCarouselProvider);

    return carouselAsync.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            children: [
              _buildCarousel(products),
              const SizedBox(height: 12),
              _buildIndicators(products.length),
            ],
          ),
        );
      },
      loading: () => const CarouselSkeleton(),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCarousel(List<Product> products) {
    return SizedBox(
      height: MediaQuery.of(context).size.height * 0.25,
      child: CarouselSlider.builder(
        carouselController: _controller,
        itemCount: products.length,
        itemBuilder: (context, index, _) {
          final product = products[index];
          return Semantics(
            label:
                '${product.name}, ${_formatPrice(product.discountPrice)}',
            button: true,
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 4),
              child: Material(
                borderRadius: BorderRadius.circular(12),
                elevation: 2,
                child: InkWell(
                  borderRadius: BorderRadius.circular(12),
                  onTap: () => _navigateToProduct(context, product),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(12),
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        CachedNetworkImage(
                          imageUrl: product.imageUrl,
                          fit: BoxFit.cover,
                          memCacheHeight: 400,
                          memCacheWidth: 600,
                          placeholder: (_, __) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest),
                          errorWidget: (_, __, ___) => Container(
                              color: Theme.of(context)
                                  .colorScheme
                                  .surfaceContainerHighest,
                              child: const Icon(Icons.error_outline,
                                  size: 40)),
                        ),
                        _CarouselOverlay(product: product),
                      ],
                    ),
                  ),
                ),
              ),
            ),
          );
        },
        options: CarouselOptions(
          viewportFraction: 1.0,
          autoPlay: true,
          autoPlayInterval: const Duration(seconds: 4),
          autoPlayAnimationDuration: const Duration(milliseconds: 800),
          autoPlayCurve: Curves.fastOutSlowIn,
          onPageChanged: (index, _) => _indexNotifier.value = index,
        ),
      ),
    );
  }

  Widget _buildIndicators(int length) {
    final cs = Theme.of(context).colorScheme;
    return ValueListenableBuilder<int>(
      valueListenable: _indexNotifier,
      builder: (context, currentIndex, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(length, (index) {
            final isActive = index == currentIndex;
            return GestureDetector(
              onTap: () {
                _controller.animateToPage(index);
                _indexNotifier.value = index;
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                height: 8,
                width: isActive ? 24 : 8,
                margin: const EdgeInsets.symmetric(horizontal: 2),
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(4),
                  color: isActive
                      ? cs.primary
                      : cs.surfaceContainerHighest,
                ),
              ),
            );
          }),
        );
      },
    );
  }
}

class _CarouselOverlay extends StatelessWidget {
  final Product product;
  const _CarouselOverlay({required this.product});

  @override
  Widget build(BuildContext context) {
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
                Colors.black.withValues(alpha: 0.7)],
          ),
        ),
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(product.name,
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.bold),
                maxLines: 1,
                overflow: TextOverflow.ellipsis),
            const SizedBox(height: 4),
            Text(_formatPrice(product.discountPrice),
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.w500)),
          ],
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Categories — watches homeCategoriesProvider independently
// ═══════════════════════════════════════════════════════════════════════════
class _CategoriesSection extends ConsumerWidget {
  const _CategoriesSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final categoriesAsync = ref.watch(homeCategoriesProvider);

    return categoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) return const SizedBox.shrink();
        return Column(
          children: [
            _SectionHeader(
              title: 'Categories',
              onViewAll: () {
                final allProducts = <Product>[];
                categories.forEach((_, data) {
                  allProducts
                      .addAll(data['products'] as List<Product>? ?? []);
                });
                Navigator.of(context).push(MaterialPageRoute(
                  builder: (_) => ProductListingPage(
                    title: 'All Categories',
                    products: allProducts,
                    categoryName: 'All Categories',
                  ),
                ));
              },
            ),
            _CategoriesList(categories: categories),
          ],
        );
      },
      loading: () => const Column(
        children: [
          _SectionHeader(title: 'Categories'),
          CategoriesSkeleton(),
        ],
      ),
      error: (e, _) => SectionError(
        message: 'Could not load categories',
        onRetry: () => ref.invalidate(homeCategoriesProvider),
      ),
    );
  }
}

class _CategoriesList extends StatelessWidget {
  final Map<String, Map<String, dynamic>> categories;
  const _CategoriesList({required this.categories});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final itemsPerRow =
            screenWidth < 600 ? 4 : (screenWidth < 1024 ? 6 : 8);
        final itemWidth =
            (screenWidth - (itemsPerRow + 1) * 8) / itemsPerRow;
        final clampedWidth = itemWidth.clamp(70.0, 120.0);

        return SizedBox(
          height: clampedWidth + 40,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: categories.length,
            cacheExtent: screenWidth * 2,
            itemBuilder: (context, index) {
              final name = categories.keys.elementAt(index);
              final data = categories[name]!;
              return Semantics(
                label: '$name category',
                button: true,
                child: Container(
                  width: clampedWidth,
                  margin: const EdgeInsets.symmetric(
                      horizontal: 8, vertical: 4),
                  child: Material(
                    color: Theme.of(context)
                        .colorScheme
                        .surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(12),
                    elevation: 1,
                    child: InkWell(
                      borderRadius: BorderRadius.circular(12),
                      onTap: () {
                        Navigator.of(context).push(MaterialPageRoute(
                          builder: (_) => ProductDetails(
                            key: ValueKey(name),
                            categoryName: name,
                            categoryImageUrl: data['imageUrl'] as String,
                            subcategories:
                                data['subcategories'] as List<String>,
                            products: data['products'] as List<Product>,
                          ),
                        ));
                      },
                      child: Padding(
                        padding: const EdgeInsets.all(6),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Expanded(
                              flex: 3,
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(8),
                                child: CachedNetworkImage(
                                  imageUrl: data['imageUrl'] as String,
                                  fit: BoxFit.cover,
                                  memCacheHeight: 120,
                                  memCacheWidth: 120,
                                  placeholder: (_, __) => Icon(
                                      Icons.category,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      size: 25),
                                  errorWidget: (_, __, ___) => Icon(
                                      Icons.error_outline,
                                      color: Theme.of(context)
                                          .colorScheme
                                          .onSurfaceVariant,
                                      size: 25),
                                ),
                              ),
                            ),
                            const SizedBox(height: 4),
                            Expanded(
                              flex: 2,
                              child: Text(name,
                                  style: const TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w500),
                                  textAlign: TextAlign.center,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Generic product section — watches any FutureProvider<List<Product>>
// Each instance rebuilds independently (key performance win)
// ═══════════════════════════════════════════════════════════════════════════
class _HomeProductSection extends ConsumerWidget {
  final FutureProvider<List<Product>> provider;
  final String title;

  const _HomeProductSection({
    required this.provider,
    required this.title,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncProducts = ref.watch(provider);

    return asyncProducts.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              _SectionHeader(
                title: title,
                onViewAll: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProductListingPage(
                      title: title,
                      products: products,
                      categoryName: title,
                    ),
                  ));
                },
              ),
              const SizedBox(height: 10),
              _HorizontalProductList(products: products),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: [
            _SectionHeader(title: title),
            const SizedBox(height: 10),
            const HorizontalListSkeleton(),
          ],
        ),
      ),
      error: (e, _) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: SectionError(
          message: 'Could not load $title',
          onRetry: () => ref.invalidate(provider),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Promotions section — special card design with PROMO badge
// ═══════════════════════════════════════════════════════════════════════════
class _HomePromotionsSection extends ConsumerWidget {
  const _HomePromotionsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final asyncPromos = ref.watch(homePromotionsProvider);

    return asyncPromos.when(
      data: (products) {
        if (products.isEmpty) return const SizedBox.shrink();
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 10),
          child: Column(
            children: [
              _SectionHeader(
                title: 'Promotion',
                onViewAll: () {
                  Navigator.of(context).push(MaterialPageRoute(
                    builder: (_) => ProductListingPage(
                      title: 'Promotional Products',
                      products: products,
                      categoryName: 'Promotional Products',
                    ),
                  ));
                },
              ),
              const SizedBox(height: 10),
              _HorizontalPromotionList(products: products),
            ],
          ),
        );
      },
      loading: () => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Column(
          children: const [
            _SectionHeader(title: 'Promotion'),
            SizedBox(height: 10),
            HorizontalListSkeleton(),
          ],
        ),
      ),
      error: (e, _) => SectionError(
        message: 'Could not load promotions',
        onRetry: () => ref.invalidate(homePromotionsProvider),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Search results — watches homeSearchResultsProvider
// ═══════════════════════════════════════════════════════════════════════════
class _SearchResultsSection extends ConsumerWidget {
  const _SearchResultsSection();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final resultsAsync = ref.watch(homeSearchResultsProvider);

    return resultsAsync.when(
      data: (products) {
        if (products.isEmpty) {
          return const Padding(
            padding: EdgeInsets.all(32),
            child: Center(
              child: Text('No products found',
                  style: TextStyle(color: Colors.grey, fontSize: 16)),
            ),
          );
        }
        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Search Results',
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold)),
              const SizedBox(height: 10),
              _HorizontalProductList(products: products),
            ],
          ),
        );
      },
      loading: () => const Padding(
        padding: EdgeInsets.symmetric(horizontal: 16),
        child: HorizontalListSkeleton(),
      ),
      error: (_, __) =>
          const SectionError(message: 'Search failed'),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Section header — title + accessible "View All" TextButton
// ═══════════════════════════════════════════════════════════════════════════
class _SectionHeader extends StatelessWidget {
  final String title;
  final VoidCallback? onViewAll;
  const _SectionHeader({required this.title, this.onViewAll});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(title,
              style: const TextStyle(
                  fontSize: 18, fontWeight: FontWeight.bold)),
          if (onViewAll != null)
            TextButton(
              onPressed: onViewAll,
              child: Text('View All',
                  style: TextStyle(
                      color: Theme.of(context).colorScheme.primary,
                      fontSize: 14)),
            ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Horizontal product list (shared by Popular, Latest, Recommended, Search)
// ═══════════════════════════════════════════════════════════════════════════
class _HorizontalProductList extends StatelessWidget {
  final List<Product> products;
  const _HorizontalProductList({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final cardWidth = (screenWidth * 0.4).clamp(140.0, 200.0);
        final sectionHeight = cardWidth * 1.5;

        return SizedBox(
          height: sectionHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            cacheExtent: screenWidth * 1.5,
            itemBuilder: (context, index) =>
                _ProductCard(
                    product: products[index], cardWidth: cardWidth),
          ),
        );
      },
    );
  }
}

class _HorizontalPromotionList extends StatelessWidget {
  final List<Product> products;
  const _HorizontalPromotionList({required this.products});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final screenWidth = constraints.maxWidth;
        final cardWidth = (screenWidth * 0.4).clamp(140.0, 200.0);
        final sectionHeight = cardWidth * 1.5;

        return SizedBox(
          height: sectionHeight,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            physics: const BouncingScrollPhysics(),
            itemCount: products.length,
            cacheExtent: screenWidth * 1.5,
            itemBuilder: (context, index) =>
                _PromotionCard(
                    product: products[index], cardWidth: cardWidth),
          ),
        );
      },
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Product card
// ═══════════════════════════════════════════════════════════════════════════
class _ProductCard extends StatelessWidget {
  final Product product;
  final double cardWidth;
  const _ProductCard({required this.product, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final hasDiscount =
        product.salePrice > 0 &&
        product.salePrice != product.discountPrice;
    final discountPct = hasDiscount
        ? ((1 - (product.discountPrice / product.salePrice)) * 100)
        : 0.0;
    final imageH = cardWidth * 0.8125;

    return Semantics(
      label:
          '${product.name}, ${_formatPrice(product.discountPrice)}'
          '${hasDiscount ? ', ${discountPct.toStringAsFixed(0)}% off' : ''}',
      button: true,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(left: 12, right: 4),
        child: Material(
          borderRadius: BorderRadius.circular(12),
          elevation: 2,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToProduct(context, product),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _CardImage(
                  product: product,
                  width: cardWidth,
                  height: imageH,
                  hasDiscount: hasDiscount,
                  discountPct: discountPct,
                ),
                Expanded(
                  child: _CardInfo(
                    product: product,
                    hasDiscount: hasDiscount,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Promotion card — PROMO badge
// ═══════════════════════════════════════════════════════════════════════════
class _PromotionCard extends StatelessWidget {
  final Product product;
  final double cardWidth;
  const _PromotionCard({required this.product, required this.cardWidth});

  @override
  Widget build(BuildContext context) {
    final hasDiscount = product.discountPrice > 0 &&
        product.discountPrice != product.salePrice;
    final discountPct = hasDiscount
        ? ((1 - (product.discountPrice / product.salePrice)) * 100)
        : 0.0;
    final imageH = cardWidth * 0.8125;

    return Semantics(
      label:
          'Promotion: ${product.name}, ${_formatPrice(product.discountPrice)}',
      button: true,
      child: Container(
        width: cardWidth,
        margin: const EdgeInsets.only(left: 12, right: 4),
        child: Material(
          borderRadius: BorderRadius.circular(12),
          elevation: 3,
          child: InkWell(
            borderRadius: BorderRadius.circular(12),
            onTap: () => _navigateToProduct(context, product),
            child: Stack(
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _CardImage(
                      product: product,
                      width: cardWidth,
                      height: imageH,
                      hasDiscount: hasDiscount,
                      discountPct: discountPct,
                    ),
                    Expanded(
                      child: _CardInfo(
                        product: product,
                        hasDiscount: hasDiscount,
                      ),
                    ),
                  ],
                ),
                Positioned(
                  top: 0,
                  left: 0,
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                        horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppTheme.promoBadgeColor(context),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(12),
                        bottomRight: Radius.circular(8),
                      ),
                    ),
                    child: const Text('PROMO',
                        style: TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 10)),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Shared card sub-widgets
// ═══════════════════════════════════════════════════════════════════════════
class _CardImage extends StatelessWidget {
  final Product product;
  final double width;
  final double height;
  final bool hasDiscount;
  final double discountPct;

  const _CardImage({
    required this.product,
    required this.width,
    required this.height,
    required this.hasDiscount,
    required this.discountPct,
  });

  @override
  Widget build(BuildContext context) {
    return Stack(
      children: [
        ClipRRect(
          borderRadius:
              const BorderRadius.vertical(top: Radius.circular(12)),
          child: CachedNetworkImage(
            imageUrl: product.imageUrl,
            height: height,
            width: width,
            fit: BoxFit.cover,
            memCacheHeight: 260,
            memCacheWidth: 320,
            placeholder: (_, __) => Container(
              height: height,
              width: width,
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
            errorWidget: (_, __, ___) => Container(
              height: height,
              width: width,
              color:
                  Theme.of(context).colorScheme.surfaceContainerHighest,
              child: Icon(Icons.error_outline,
                  color:
                      Theme.of(context).colorScheme.onSurfaceVariant,
                  size: 40),
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
                color: AppTheme.discountBadgeColor(context),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                '${discountPct.toStringAsFixed(0)}%',
                style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12),
              ),
            ),
          ),
      ],
    );
  }
}

class _CardInfo extends StatelessWidget {
  final Product product;
  final bool hasDiscount;
  const _CardInfo({required this.product, required this.hasDiscount});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Flexible(
            child: Text(product.name,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    height: 1.1),
                maxLines: 2,
                overflow: TextOverflow.ellipsis),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(_formatPrice(product.discountPrice),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: AppTheme.priceColor(context),
                      fontSize: 14)),
              if (hasDiscount)
                Text(_formatPrice(product.salePrice),
                    style: TextStyle(
                        decoration: TextDecoration.lineThrough,
                        color: Theme.of(context)
                            .colorScheme
                            .onSurfaceVariant,
                        fontSize: 11)),
            ],
          ),
        ],
      ),
    );
  }
}

// ═══════════════════════════════════════════════════════════════════════════
// Navigation helper
// ═══════════════════════════════════════════════════════════════════════════
void _navigateToProduct(BuildContext context, Product product) {
  Navigator.of(context).push(
    MaterialPageRoute(
      builder: (_) => ProductDetails(
        key: ValueKey(product.name),
        products: [product],
        categoryName: product.category,
        categoryImageUrl: product.imageUrl,
        subcategories: [],
      ),
    ),
  );
}
