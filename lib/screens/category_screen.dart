import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/cart_icon_with_badge.dart';
import 'package:zalonidentalhub/providers/category_providers.dart';
import 'package:zalonidentalhub/widgets/category_widgets.dart';

// ---------------------------------------------------------------------------
// Breakpoints — Material 3 canonical window size classes
// ---------------------------------------------------------------------------
const double _kCompactBreakpoint = 600;
const double _kMediumBreakpoint = 1240;

// ===========================================================================
// CategoriesScreen
// ===========================================================================
class CategoriesScreen extends ConsumerStatefulWidget {
  const CategoriesScreen({super.key});

  @override
  ConsumerState<CategoriesScreen> createState() => _CategoriesScreenState();
}

class _CategoriesScreenState extends ConsumerState<CategoriesScreen>
    with RestorationMixin {
  late final SearchController _searchController;
  final ScrollController _scrollController = ScrollController();
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  // Restoration properties — survive config changes & process death
  final RestorableString _restorableSearchQuery = RestorableString('');
  final RestorableString _restorableCategory = RestorableString('');

  // -----------------------------------------------------------------------
  // RestorationMixin
  // -----------------------------------------------------------------------
  @override
  String? get restorationId => 'categories_screen';

  @override
  void restoreState(RestorationBucket? oldBucket, bool initialRestore) {
    registerForRestoration(_restorableSearchQuery, 'search_query');
    registerForRestoration(_restorableCategory, 'selected_category');

    if (initialRestore) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        // Restore search query
        final query = _restorableSearchQuery.value;
        if (query.isNotEmpty) {
          _searchController.text = query;
          ref.read(categorySearchProvider.notifier).update(query);
        }
        // Restore selected category ('' means "all")
        final category = _restorableCategory.value;
        if (category.isNotEmpty) {
          ref.read(selectedCategoryProvider.notifier).select(category);
        }
      });
    }
  }

  // -----------------------------------------------------------------------
  // Lifecycle
  // -----------------------------------------------------------------------
  @override
  void initState() {
    super.initState();
    _searchController = SearchController();
    _searchController.addListener(_onSearchTextChanged);
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _restorableSearchQuery.dispose();
    _restorableCategory.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    _searchController.removeListener(_onSearchTextChanged);
    _searchController.dispose();
    super.dispose();
  }

  /// Sync SearchController text → restorable + debounced provider.
  void _onSearchTextChanged() {
    _restorableSearchQuery.value = _searchController.text;
    ref.read(categorySearchProvider.notifier).update(_searchController.text);
  }

  /// Infinite scroll — trigger load-more near bottom.
  void _onScroll() {
    if (!_scrollController.hasClients) return;
    final max = _scrollController.position.maxScrollExtent;
    final cur = _scrollController.position.pixels;
    if (max - cur <= 200) {
      ref.read(paginatedProductsProvider.notifier).loadMore();
    }
  }

  /// Select a category and persist for restoration.
  void _selectCategory(String? category) {
    _restorableCategory.value = category ?? '';
    ref.read(selectedCategoryProvider.notifier).select(category);
  }

  int _crossAxisCount(double width) {
    if (width > _kMediumBreakpoint) return 4;
    if (width > _kCompactBreakpoint) return 3;
    return 2;
  }

  // -----------------------------------------------------------------------
  // Build
  // -----------------------------------------------------------------------
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
          drawer: isCompact ? _buildCategoryDrawer(context) : null,
          body: isCompact
              ? _buildCompactBody(context)
              : _buildWideBody(context, isExpanded),
        );
      },
    );
  }

  // -----------------------------------------------------------------------
  // App Bar — only watches viewMode (narrow rebuild scope)
  // -----------------------------------------------------------------------
  PreferredSizeWidget _buildAppBar(BuildContext context, bool isCompact) {
    final viewMode = ref.watch(productViewModeProvider);

    return AppBar(
      leading: isCompact
          ? IconButton(
              icon: const Icon(Icons.menu),
              tooltip: 'Open categories drawer',
              onPressed: () => _scaffoldKey.currentState?.openDrawer(),
            )
          : null,
      title: const Text('Categories'),
      actions: [
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
            _buildAllCategoriesOption(context, closeDrawer: true),
            const Divider(height: 1),
            Expanded(child: _buildCategoryListView(context, closeDrawer: true)),
          ],
        ),
      ),
    );
  }

  Widget _buildAllCategoriesOption(BuildContext context,
      {bool closeDrawer = false}) {
    final selected = ref.watch(selectedCategoryProvider);
    final isAll = selected == null;

    return ListTile(
      leading: Icon(
        Icons.dashboard_outlined,
        color: isAll ? Theme.of(context).colorScheme.primary : null,
      ),
      title: Text(
        'All Products',
        style: TextStyle(
          fontWeight: isAll ? FontWeight.bold : FontWeight.normal,
        ),
      ),
      selected: isAll,
      onTap: () {
        _selectCategory(null);
        if (closeDrawer) Navigator.of(context).pop();
      },
    );
  }

  // -----------------------------------------------------------------------
  // Category sidebar — medium & expanded layouts (≥600dp)
  // -----------------------------------------------------------------------
  Widget _buildCategorySidebar(BuildContext context, bool isExpanded) {
    final theme = Theme.of(context);
    return SizedBox(
      width: isExpanded ? 260 : 220,
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: theme.colorScheme.outlineVariant),
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
          _buildSidebarAllOption(context),
          const Divider(height: 1),
          Expanded(
              child: _buildCategoryListView(context, closeDrawer: false)),
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
      onTap: () => _selectCategory(null),
    );
  }

  // -----------------------------------------------------------------------
  // Shared category list — used by drawer and sidebar
  // -----------------------------------------------------------------------
  Widget _buildCategoryListView(BuildContext context,
      {required bool closeDrawer}) {
    final filteredAsync = ref.watch(filteredCategoryListProvider);

    return filteredAsync.when(
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
                _selectCategory(cat.name);
                if (closeDrawer) Navigator.of(context).pop();
              },
            );
          },
        );
      },
      loading: () => const ShimmerCategorySidebar(),
      error: (err, _) => ErrorRetryCard(
        message: 'Could not load dental service categories',
        onRetry: () => ref.invalidate(categoryListProvider),
      ),
    );
  }

  // -----------------------------------------------------------------------
  // Compact body — full-width content with pull-to-refresh
  // -----------------------------------------------------------------------
  Widget _buildCompactBody(BuildContext context) {
    return RefreshIndicator(
      onRefresh: () =>
          ref.read(paginatedProductsProvider.notifier).refresh(),
      child: _buildProductContent(context),
    );
  }

  // -----------------------------------------------------------------------
  // Wide body — sidebar + content side by side
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
  // Product content — SliverAppBar with SearchAnchor + product slivers
  // -----------------------------------------------------------------------
  Widget _buildProductContent(BuildContext context) {
    // Use ref.select for the loading/error state decision so the grid
    // doesn't rebuild when only isLoadingMore changes.
    final isLoading = ref.watch(
        paginatedProductsProvider.select((s) => s.isLoading));
    final error = ref.watch(
        paginatedProductsProvider.select((s) => s.error));
    final productsEmpty = ref.watch(
        paginatedProductsProvider.select((s) => s.products.isEmpty));
    final filteredProducts = ref.watch(filteredCategoryProductsProvider);
    final viewMode = ref.watch(productViewModeProvider);
    final selectedCategory = ref.watch(selectedCategoryProvider);
    final searchQuery = ref.watch(categorySearchProvider);
    final crossAxisCount =
        _crossAxisCount(MediaQuery.sizeOf(context).width);

    return CustomScrollView(
      controller: _scrollController,
      restorationId: 'categories_product_scroll',
      slivers: [
        // Pinned search bar via SliverAppBar + SearchAnchor
        SliverAppBar(
          pinned: true,
          floating: true,
          snap: true,
          automaticallyImplyLeading: false,
          toolbarHeight: 68,
          surfaceTintColor: Colors.transparent,
          title: _buildSearchAnchor(context),
        ),

        // Breadcrumb
        SliverToBoxAdapter(
          child: _buildBreadcrumb(context, selectedCategory),
        ),

        // Content states
        if (isLoading)
          SliverFillRemaining(
            child: ShimmerProductGrid(crossAxisCount: crossAxisCount),
          )
        else if (error != null && productsEmpty)
          SliverFillRemaining(
            child: ErrorRetryCard(
              message: 'Could not load dental products. '
                  'Please check your connection and try again.',
              onRetry: () =>
                  ref.read(paginatedProductsProvider.notifier).refresh(),
            ),
          )
        else if (filteredProducts.isEmpty)
          SliverFillRemaining(
            child: EmptyStateWidget(
              message: selectedCategory != null
                  ? 'No treatments found in $selectedCategory'
                  : 'No dental products found',
              subtitle: searchQuery.isNotEmpty
                  ? 'No results for "$searchQuery" \u2014 try a different term'
                  : 'Try selecting another category or adjusting your filters',
              icon: Icons.medical_services_outlined,
            ),
          )
        else ...[
          // Pagination info — uses Consumer + ref.select to avoid
          // rebuilding the grid when only totalLoaded changes.
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final totalLoaded = ref.watch(
                    paginatedProductsProvider.select((s) => s.totalLoaded));
                final hasMore = ref.watch(
                    paginatedProductsProvider.select((s) => s.hasMore));
                return PaginationInfoBar(
                    loaded: totalLoaded, hasMore: hasMore);
              },
            ),
          ),

          // Product grid or list
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
                  childAspectRatio: 0.68,
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

          // Load-more footer — isolated Consumer to avoid rebuilding
          // the product grid when isLoadingMore toggles.
          SliverToBoxAdapter(
            child: Consumer(
              builder: (context, ref, _) {
                final isLoadingMore = ref.watch(
                    paginatedProductsProvider.select((s) => s.isLoadingMore));
                final hasMore = ref.watch(
                    paginatedProductsProvider.select((s) => s.hasMore));
                final isStillLoading = ref.watch(
                    paginatedProductsProvider.select((s) => s.isLoading));

                if (isLoadingMore) {
                  return const Padding(
                    padding: EdgeInsets.all(16),
                    child: Center(
                      child: SizedBox(
                        width: 24,
                        height: 24,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    ),
                  );
                }
                if (hasMore && !isStillLoading) {
                  return Padding(
                    padding: const EdgeInsets.all(16),
                    child: Center(
                      child: OutlinedButton.icon(
                        onPressed: () => ref
                            .read(paginatedProductsProvider.notifier)
                            .loadMore(),
                        icon: const Icon(Icons.expand_more),
                        label: const Text('Load more products'),
                      ),
                    ),
                  );
                }
                return const SizedBox.shrink();
              },
            ),
          ),

          // Bottom safe-area
          const SliverPadding(padding: EdgeInsets.only(bottom: 80)),
        ],
      ],
    );
  }

  // -----------------------------------------------------------------------
  // SearchAnchor — with recent searches + category suggestions
  // -----------------------------------------------------------------------
  Widget _buildSearchAnchor(BuildContext context) {
    return SearchAnchor(
      searchController: _searchController,
      isFullScreen: false,
      viewHintText: 'Search dental treatments, products...',
      viewOnSubmitted: (query) {
        _searchController.closeView(query);
        if (query.trim().isNotEmpty) {
          ref.read(recentSearchesProvider.notifier).add(query.trim());
        }
      },
      builder: (context, controller) {
        return SearchBar(
          controller: controller,
          hintText: 'Search dental products...',
          leading: const Padding(
            padding: EdgeInsets.only(left: 8),
            child: Icon(Icons.search),
          ),
          trailing: [
            if (controller.text.isNotEmpty)
              IconButton(
                icon: const Icon(Icons.clear, size: 20),
                tooltip: 'Clear search',
                onPressed: () {
                  controller.clear();
                  _restorableSearchQuery.value = '';
                  ref.read(categorySearchProvider.notifier).clear();
                },
              ),
          ],
          onTap: () => controller.openView(),
          onChanged: (query) {
            // Inline filtering via debounced provider
            _restorableSearchQuery.value = query;
            ref.read(categorySearchProvider.notifier).update(query);
          },
          elevation: WidgetStateProperty.all(1.0),
          shape: WidgetStateProperty.all(
            RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
          ),
        );
      },
      suggestionsBuilder: (context, controller) {
        final query = controller.text.toLowerCase().trim();
        final suggestions = <Widget>[];

        if (query.isEmpty) {
          // --- Recent searches ---
          final recent = ref.read(recentSearchesProvider);
          if (recent.isNotEmpty) {
            suggestions.add(Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Recent searches',
                  style: Theme.of(context).textTheme.labelMedium),
            ));
            for (final term in recent) {
              suggestions.add(ListTile(
                leading: const Icon(Icons.history, size: 20),
                title: Text(term),
                trailing: IconButton(
                  icon: const Icon(Icons.close, size: 16),
                  tooltip: 'Remove from recent',
                  onPressed: () {
                    ref.read(recentSearchesProvider.notifier).remove(term);
                    // Rebuild suggestions
                    controller.text = controller.text;
                  },
                ),
                onTap: () {
                  controller.closeView(term);
                  _restorableSearchQuery.value = term;
                  ref.read(categorySearchProvider.notifier).update(term);
                },
              ));
            }
          }

          // --- Popular categories ---
          final categories =
              ref.read(categoryListProvider).value ?? [];
          if (categories.isNotEmpty) {
            suggestions.add(Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
              child: Text('Browse categories',
                  style: Theme.of(context).textTheme.labelMedium),
            ));
            for (final cat in categories.take(6)) {
              suggestions.add(ListTile(
                leading: const Icon(Icons.category_outlined, size: 20),
                title: Text(cat.name),
                trailing: Text(
                  '${cat.productCount}',
                  style: Theme.of(context).textTheme.labelSmall,
                ),
                onTap: () {
                  controller.closeView('');
                  _selectCategory(cat.name);
                  ref.read(categorySearchProvider.notifier).clear();
                },
              ));
            }
          }
        } else {
          // --- Matching categories ---
          final categories =
              ref.read(categoryListProvider).value ?? [];
          final matching = categories
              .where((c) => c.name.toLowerCase().contains(query))
              .toList();

          for (final cat in matching) {
            suggestions.add(ListTile(
              leading: const Icon(Icons.category_outlined, size: 20),
              title: Text(cat.name),
              subtitle: Text('${cat.productCount} dental products'),
              onTap: () {
                controller.closeView(cat.name);
                _selectCategory(cat.name);
                ref.read(recentSearchesProvider.notifier).add(cat.name);
                ref.read(categorySearchProvider.notifier).clear();
              },
            ));
          }

          // Hint if no category matches (products will still be filtered)
          if (matching.isEmpty) {
            suggestions.add(ListTile(
              leading: const Icon(Icons.search, size: 20),
              title: Text('Search for "$query"'),
              subtitle: const Text('Filter products by name'),
              onTap: () {
                controller.closeView(query);
                ref.read(recentSearchesProvider.notifier).add(query);
              },
            ));
          }
        }

        return suggestions;
      },
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
            onTap: () => _selectCategory(null),
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
