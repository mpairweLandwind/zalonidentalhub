import 'package:cached_network_image/cached_network_image.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../models/cart_item.dart';
import '../models/cart_model.dart';
import '../models/product.dart';
import '../screens/product_details.dart';
import '../theme/app_theme.dart';
import 'shimmer_loading.dart';

// ---------------------------------------------------------------------------
// Price formatting helper
// ---------------------------------------------------------------------------
String formatPrice(double price) {
  return 'UGX ${price.toStringAsFixed(0).replaceAllMapped(
        RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
        (Match m) => '${m[1]},',
      )}';
}

// ---------------------------------------------------------------------------
// Product Grid Tile — used in both grid and list layouts.
// Includes: CachedNetworkImage with memCacheWidth, semantics, discount badge.
// ---------------------------------------------------------------------------
class ProductGridTile extends ConsumerWidget {
  final Product product;

  const ProductGridTile({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDiscount =
        product.salePrice > 0 && product.salePrice != product.discountPrice;
    final discountPct = product.percentageReduction;
    final theme = Theme.of(context);

    return Semantics(
      label: '${product.name}, '
          '${formatPrice(product.discountPrice)}'
          '${hasDiscount ? ', was ${formatPrice(product.salePrice)}, ${discountPct.toStringAsFixed(0)}% off' : ''}',
      button: true,
      child: Card(
        elevation: 2,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
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
          },
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Image section
              Expanded(
                flex: 3,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    CachedNetworkImage(
                      imageUrl: product.imageUrl,
                      fit: BoxFit.cover,
                      memCacheWidth: 300,
                      memCacheHeight: 300,
                      placeholder: (_, __) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: const Center(
                          child: SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          ),
                        ),
                      ),
                      errorWidget: (_, __, ___) => Container(
                        color: theme.colorScheme.surfaceContainerHighest,
                        child: Icon(
                          Icons.broken_image_outlined,
                          size: 32,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                      ),
                    ),
                    if (hasDiscount)
                      Positioned(
                        top: 6,
                        right: 6,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 3),
                          decoration: BoxDecoration(
                            color: AppTheme.discountBadgeColor(context),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            '-${discountPct.toStringAsFixed(0)}%',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
              // Info section
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
                          style: theme.textTheme.bodySmall?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        formatPrice(product.discountPrice),
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: AppTheme.priceColor(context),
                        ),
                      ),
                      if (hasDiscount)
                        Text(
                          formatPrice(product.salePrice),
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Product List Tile — horizontal card for list view mode
// ---------------------------------------------------------------------------
class ProductListTile extends ConsumerWidget {
  final Product product;

  const ProductListTile({super.key, required this.product});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final hasDiscount =
        product.salePrice > 0 && product.salePrice != product.discountPrice;
    final discountPct = product.percentageReduction;
    final theme = Theme.of(context);

    return Semantics(
      label: '${product.name}, ${formatPrice(product.discountPrice)}',
      button: true,
      child: Card(
        elevation: 1,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: () {
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
          },
          child: SizedBox(
            height: 100,
            child: Row(
              children: [
                SizedBox(
                  width: 100,
                  child: Stack(
                    fit: StackFit.expand,
                    children: [
                      CachedNetworkImage(
                        imageUrl: product.imageUrl,
                        fit: BoxFit.cover,
                        memCacheWidth: 200,
                        memCacheHeight: 200,
                        placeholder: (_, __) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                        ),
                        errorWidget: (_, __, ___) => Container(
                          color: theme.colorScheme.surfaceContainerHighest,
                          child: const Icon(Icons.broken_image_outlined),
                        ),
                      ),
                      if (hasDiscount)
                        Positioned(
                          top: 4,
                          left: 4,
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            decoration: BoxDecoration(
                              color: AppTheme.discountBadgeColor(context),
                              borderRadius: BorderRadius.circular(6),
                            ),
                            child: Text(
                              '-${discountPct.toStringAsFixed(0)}%',
                              style: theme.textTheme.labelSmall?.copyWith(
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
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          product.name,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                          ),
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 4),
                        Text(
                          formatPrice(product.discountPrice),
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: AppTheme.priceColor(context),
                          ),
                        ),
                        if (hasDiscount)
                          Text(
                            formatPrice(product.salePrice),
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: theme.colorScheme.onSurfaceVariant,
                              decoration: TextDecoration.lineThrough,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
                // Quick add-to-cart button
                Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: IconButton(
                    icon: const Icon(Icons.add_shopping_cart_outlined),
                    tooltip: 'Add to cart',
                    onPressed: () {
                      ref.read(cartProvider.notifier).addToCart(
                            CartItem(
                              name: product.name,
                              salePrice: product.salePrice,
                              discountPrice: product.discountPrice,
                              percentageReduction:
                                  product.percentageReduction,
                              imageUrl: product.imageUrl,
                              quantity: 1,
                            ),
                          );
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                          content: Text('${product.name} added to cart'),
                          duration: const Duration(seconds: 2),
                          behavior: SnackBarBehavior.floating,
                        ),
                      );
                    },
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

// ---------------------------------------------------------------------------
// Shimmer product grid skeleton — fills available space
// ---------------------------------------------------------------------------
class ShimmerProductGrid extends StatelessWidget {
  final int crossAxisCount;

  const ShimmerProductGrid({super.key, this.crossAxisCount = 2});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: GridView.builder(
        physics: const NeverScrollableScrollPhysics(),
        padding: const EdgeInsets.all(16),
        gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: crossAxisCount,
          crossAxisSpacing: 12,
          mainAxisSpacing: 12,
          childAspectRatio: 0.75,
        ),
        itemCount: crossAxisCount * 3,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.surfaceContainerHighest,
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shimmer category sidebar skeleton
// ---------------------------------------------------------------------------
class ShimmerCategorySidebar extends StatelessWidget {
  const ShimmerCategorySidebar({super.key});

  @override
  Widget build(BuildContext context) {
    return ShimmerEffect(
      child: ListView.builder(
        padding: const EdgeInsets.all(8),
        itemCount: 8,
        itemBuilder: (_, __) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: SkeletonBox(
            width: double.infinity,
            height: 48,
            borderRadius: 8,
          ),
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Error card with retry — inline error display
// ---------------------------------------------------------------------------
class ErrorRetryCard extends StatelessWidget {
  final String message;
  final VoidCallback? onRetry;

  const ErrorRetryCard({
    super.key,
    required this.message,
    this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.error_outline,
              size: 48,
              color: theme.colorScheme.error,
            ),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyLarge,
            ),
            if (onRetry != null) ...[
              const SizedBox(height: 16),
              FilledButton.tonalIcon(
                onPressed: onRetry,
                icon: const Icon(Icons.refresh, size: 18),
                label: const Text('Retry'),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Empty state — shown when search/filter yields no results
// ---------------------------------------------------------------------------
class EmptyStateWidget extends StatelessWidget {
  final String message;
  final String? subtitle;
  final IconData icon;

  const EmptyStateWidget({
    super.key,
    required this.message,
    this.subtitle,
    this.icon = Icons.search_off_outlined,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: theme.colorScheme.onSurfaceVariant),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                color: theme.colorScheme.onSurfaceVariant,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurfaceVariant,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Pagination info footer — "Showing X–Y of Z"
// ---------------------------------------------------------------------------
class PaginationInfoBar extends StatelessWidget {
  final int loaded;
  final bool hasMore;
  final bool isLoadingMore;

  const PaginationInfoBar({
    super.key,
    required this.loaded,
    required this.hasMore,
    this.isLoadingMore = false,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Text(
            hasMore
                ? 'Showing 1–$loaded (more available)'
                : 'Showing all $loaded items',
            style: theme.textTheme.labelMedium?.copyWith(
              color: theme.colorScheme.onSurfaceVariant,
            ),
          ),
          if (isLoadingMore) ...[
            const SizedBox(width: 8),
            const SizedBox(
              width: 14,
              height: 14,
              child: CircularProgressIndicator(strokeWidth: 2),
            ),
          ],
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Category tile — sidebar item for category selection
// ---------------------------------------------------------------------------
class CategoryTile extends StatelessWidget {
  final String category;
  final int productCount;
  final bool isSelected;
  final VoidCallback onTap;

  const CategoryTile({
    super.key,
    required this.category,
    required this.productCount,
    required this.isSelected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colorScheme = theme.colorScheme;

    return Semantics(
      label: '$category, $productCount items'
          '${isSelected ? ', selected' : ''}',
      selected: isSelected,
      button: true,
      child: Container(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
        child: Material(
          color: isSelected
              ? colorScheme.primaryContainer
              : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          child: InkWell(
            borderRadius: BorderRadius.circular(8),
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              child: Row(
                children: [
                  Container(
                    width: 6,
                    height: 6,
                    decoration: BoxDecoration(
                      color: isSelected
                          ? colorScheme.primary
                          : colorScheme.onSurfaceVariant,
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
                          style: theme.textTheme.bodyMedium?.copyWith(
                            fontWeight: isSelected
                                ? FontWeight.w600
                                : FontWeight.normal,
                            color: isSelected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurface,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        Text(
                          '$productCount items',
                          style: theme.textTheme.labelSmall?.copyWith(
                            color: colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (isSelected)
                    Icon(
                      Icons.arrow_forward_ios,
                      size: 12,
                      color: colorScheme.primary,
                    ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
