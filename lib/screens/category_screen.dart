import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/providers/category_providers.dart';
import 'package:zalonidentalhub/widgets/category_widgets.dart';

// ---------------------------------------------------------------------------
// Breakpoints following Material 3 canonical layouts
// ---------------------------------------------------------------------------
const double _kCompactBreakpoint = 600;
const double _kMediumBreakpoint = 1240;

class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  void initState() {
    super.initState();
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  /// Infinite scroll — triggers load-more when near the bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final maxScroll = _scrollController.position.maxScrollExtent;
    final currentScroll = _scrollController.position.pixels;
    // Trigger load when within 200px of the bottom
    if (maxScroll - currentScroll <= 200) {
      ref.read(paginatedProductsProvider.notifier).loadMore();
    }
  }

  int _crossAxisCount(double width) {
    if (width > _kMediumBreakpoint) return 4;
    if (width > _kCompactBreakpoint) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final isCompact = width < _kCompactBreakpoint;
        final isExpanded = width >= _kMediumBreakpoint;

        return Scaffold(
          key: _scaffoldKey,
          appBar: _buildAppBar(context, isCompact),
          // On compact, categories live in a drawer
          drawer: isCompact ? _buildCategoryDrawer(context) : null,
          body: isCompact
              ? _buildCompactBody(context)
              : _buildWideBody(context, isExpanded),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // App Bar
  // -----------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isCompact) {
    final viewMode = ref.watch(productViewModeProvider);

    return AppBar(
      leading: isCompact
          ? IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open categories',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      title: const Text('Categories'),
      actions: [
        // Grid / List toggle — functional
        IconButton(
          icon: Icon(
            viewMode == ProductViewMode.grid
                ? Icons.view_list_outlined
                : Icons.grid_view_outlined,
          ),
          tooltip: viewMode == ProductViewMode.grid
              ? 'Switch to list view'
              : 'Switch to grid view',
          onPressed: () =>
              ref.read(productViewModeProvider.notifier).toggle(),
        ),
        const Padding(
          padding: EdgeInsets.only(right: 8),
          child: CartIconWithBadge(),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Category Drawer — compact layout (<600dp)
  // -----------------------------------------------------------------------
  Widget _buildCategoryDrawer(BuildContext context) {
    return Drawer(
      child: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.all(16),
              child: Text(
                'Categories',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const Divider(height: 1),
            // "All" option
            _buildAllCategoriesOption(context),
            const Divider(height: 1),
            // Category list
            Expanded(child: _buildCategoryListView(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCategoriesOption(BuildContext context) {
    final selected = ref.watch(selectedCategoryProvider);
    final isAllSelected = selected == null;

    return ListTile(
      leading: Icon(
        Icons.dashboard_outlined,
        color: isAllSelected
            ? Theme.of(context).colorScheme.primary
            : null,
      ),
      title: Text(
        'All Products',
        style: TextStyle(
          fontWeight: isAllSelected ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isAllSelected,
      onTap: () {
        ref.read(selectedCategoryProvider.notifier).select(null);
        Navigator.of(context).pop(); // close drawer
      },
    );
  }

  // -----------------------------------------------------------------------
  // Category sidebar panel — medium & expanded layouts (≥600dp)
  // -----------------------------------------------------------------------
  Widget _buildCategorySidebar(BuildContext context, bool isExpanded) {
    final theme = Theme.of(context);
    return SizedBox(
      width: isExpanded ? 260 : 220,
      child: Column(
        children: [
          // Sidebar header
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(
                  color: theme.colorScheme.outlineVariant,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(Icons.category_outlined,
                    color: theme.colorScheme.primary, size: 20),
                const SizedBox(width: 8),
                Text('Categories',
                    style: theme.textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600)),
              ],
            ),
          ),
          // "All" option
          _buildSidebarAllOption(context),
          const Divider(height: 1),
          // Scrollable category list
          Expanded(child: _buildCategoryListView(context)),
        ],
      ),
    );
  }

  Widget _buildSidebarAllOption(BuildContext context) {
    final selected = ref.watch(selectedCategoryProvider);
    return CategoryTile(
      category: 'All Products',
      productCount: 0,
      isSelected: selected == null,
      onTap: () => ref.read(selectedCategoryProvider.notifier).select(null),
    );
  }

  // -----------------------------------------------------------------------
  // Shared category list — used by both drawer and sidebar
  // -----------------------------------------------------------------------
  Widget _buildCategoryListView(BuildContext context) {
    final filteredCategoriesAsync = ref.watch(filteredCategoryListProvider);

    return filteredCategoriesAsync.when(
      data: (categories) {
        if (categories.isEmpty) {
          return const Center(
            child: Padding(
              padding: EdgeInsets.all(16),
              child: Text('No categories found'),
            ),
          );
        }
        final selected = ref.watch(selectedCategoryProvider);
        return ListView.builder(
          padding: const EdgeInsets.symmetric(vertical: 4),
          itemCount: categories.length,
          itemBuilder: (context, index) {
            final cat = categories[index];
            return CategoryTile(
              category: cat.name,
              productCount: cat.productCount,
              isSelected: cat.name == selected,
              onTap: () {
                ref.read(selectedCategoryProvider.notifier).select(cat.name);
                // Close drawer if in compact mode
                if (Scaffold.of(context).isDrawerOpen) {
                  Navigator.of(context).pop();
                }
              },
            );
          },
        );
      },
      loading: () => const ShimmerCategorySidebar(),
      error: (err, _) => ErrorRetryCard(
        message: 'Failed to load categories',
        onRetry: () => ref.invalidate(categoryListProvider),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Compact body — full-width product content with search
  // -----------------------------------------------------------------------
  Widget _buildCompactBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paginatedProductsProvider.notifier).refresh(),
      child: _buildProductContent(context),
    );
  }

  // -----------------------------------------------------------------------
  // Wide body — sidebar + product content side by side
  // -----------------------------------------------------------------------
  Widget _buildWideBody(BuildContext context, bool isExpanded) {
    return Row(
      children: [
        _buildCategorySidebar(context, isExpanded),
        VerticalDivider(
            width: 1, color: Theme.of(context).colorScheme.outlineVariant),
        Expanded(
          child: RefreshIndicator(
            onRefresh: () =>
                ref.read(paginatedProductsProvider.notifier).refresh(),
            child: _buildProductContent(context),
          ),
        ),
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Product content — search bar + breadcrumb + sliver product grid/list
  // -----------------------------------------------------------------------
  Widget _buildProductContent(BuildContext context) {
    final paginated = ref.watch(paginatedProductsProvider);
    final filteredProducts = ref.watch(filteredCategoryProductsProvider);
    final viewMode = ref.watch(productViewModeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final crossAxisCount =
        _crossAxisCount(MediaQuery.sizeOf(context).width);

    return CustomScrollView(
      controller: _scrollController,
      slivers: [
        // Pinned search bar
        SliverPersistentHeader(
          pinned: true,
          delegate: _SearchBarDelegate(
            searchController: _searchController,
            onChanged: (query) =>
                ref.read(categorySearchProvider.notifier).update(query),
            onClear: () {
              _searchController.clear();
              ref.read(categorySearchProvider.notifier).clear();
            },
          ),
        ),

        // Breadcrumb
        SliverToBoxAdapter(
          child: _buildBreadcrumb(context, selectedCategory),
        ),

        // Loading state — first load
        if (paginated.isLoading)
          SliverFillRemaining(
            child: ShimmerProductGrid(crossAxisCount: crossAxisCount),
          )
        // Error state — no data loaded yet
        else if (paginated.error != null && paginated.products.isEmpty)
          SliverFillRemaining(
            child: ErrorRetryCard(
              message: paginated.error!,
              onRetry: () =>
                  ref.read(paginatedProductsProvider.notifier).refresh(),
            ),
          )
        // Empty state
        else if (filteredProducts.isEmpty)
          const SliverFillRemaining(
            child: EmptyStateWidget(
              message: 'No products found',
              subtitle: 'Try adjusting your search or category filter',
            ),
          )
        // Products loaded
        else ...[
          // Pagination info header
          SliverToBoxAdapter(
            child: PaginationInfoBar(
              loaded: paginated.totalLoaded,
              hasMore: paginated.hasMore,
            ),
          ),
          // Products — grid or list
          if (viewMode == ProductViewMode.grid)
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverGrid(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = filteredProducts[index];
                    return ProductGridTile(
                      key: ValueKey(product.documentId ?? product.name),
                      product: product,
                    );
                  },
                  childCount: filteredProducts.length,
                ),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: crossAxisCount,
                  crossAxisSpacing: 8,
                  mainAxisSpacing: 8,
                  childAspectRatio: 0.72,
                ),
              ),
            )
          else
            SliverPadding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              sliver: SliverList(
                delegate: SliverChildBuilderDelegate(
                  (context, index) {
                    final product = filteredProducts[index];
                    return ProductListTile(
                      key: ValueKey(product.documentId ?? product.name),
                      product: product,
                    );
                  },
                  childCount: filteredProducts.length,
                ),
              ),
            ),

          // Load-more spinner at bottom
          if (paginated.isLoadingMore)
            const SliverToBoxAdapter(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Center(
                  child: SizedBox(
                    width: 24,
                    height: 24,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
                ),
              ),
            ),

          // Explicit "Load more" button
          if (paginated.hasMore &&
              !paginated.isLoadingMore &&
              !paginated.isLoading)
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Center(
                  child: OutlinedButton.icon(
                    onPressed: () => ref
                        .read(paginatedProductsProvider.notifier)
                        .loadMore(),
                    icon: const Icon(Icons.expand_more),
                    label: const Text('Load more'),
                  ),
                ),
              ),
            ),

          // Bottom safe-area padding
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ],
    );
  }

  // -----------------------------------------------------------------------
  // Breadcrumb bar
  // -----------------------------------------------------------------------
  Widget _buildBreadcrumb(BuildContext context, String? selectedCategory) {
    final theme = Theme.of(context);
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: Row(
        children: [
          InkWell(
            borderRadius: BorderRadius.circular(4),
            onTap: () =>
                ref.read(selectedCategoryProvider.notifier).select(null),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.home_outlined,
                      size: 16, color: theme.colorScheme.primary),
                  const SizedBox(width: 4),
                  Text(
                    'All',
                    style: theme.textTheme.labelLarge?.copyWith(
                      color: theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
          if (selectedCategory != null) ...[
            Icon(Icons.chevron_right,
                size: 18, color: theme.colorScheme.onSurfaceVariant),
            Expanded(
              child: Text(
                selectedCategory,
                style: theme.textTheme.labelLarge?.copyWith(
                  color: theme.colorScheme.primary,
                  fontWeight: FontWeight.w600,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// SliverPersistentHeaderDelegate — pinned search bar
// ---------------------------------------------------------------------------
class _SearchBarDelegate extends SliverPersistentHeaderDelegate {
  final TextEditingController searchController;
  final ValueChanged<String> onChanged;
  final VoidCallback onClear;

  const _SearchBarDelegate({
    required this.searchController,
    required this.onChanged,
    required this.onClear,
  });

  @override
  double get maxExtent => 72;

  @override
  double get minExtent => 72;

  @override
  bool shouldRebuild(covariant _SearchBarDelegate oldDelegate) => false;

  @override
  Widget build(
      BuildContext context, double shrinkOffset, bool overlapsContent) {
    final theme = Theme.of(context);
    return Container(
      color: theme.colorScheme.surface,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      child: SearchBar(
        controller: searchController,
        hintText: 'Search products...',
        leading: const Padding(
          padding: EdgeInsets.only(left: 8),
          child: Icon(Icons.search),
        ),
        trailing: [
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: const Icon(Icons.clear, size: 20),
              onPressed: onClear,
            ),
        ],
        onChanged: onChanged,
        elevation: WidgetStateProperty.all(overlapsContent ? 2.0 : 0.0),
        shape: WidgetStateProperty.all(
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      ),
    );
  }
}
