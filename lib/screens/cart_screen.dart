import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zalonidentalhub/models/cart_item.dart';
import 'package:zalonidentalhub/models/cart_model.dart';
import 'package:zalonidentalhub/models/user_model.dart';
import 'package:zalonidentalhub/providers/authprovider.dart';

class CartScreen extends ConsumerWidget {
  const CartScreen({super.key});

  static String formatPrice(double price) {
    return 'UGX ${price.toStringAsFixed(0).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cartItems = ref.watch(cartProvider);
    final isAuthenticated =
        ref.watch(authProvider.select((s) => s.isAuthenticated));
    final userModel = ref.watch(authProvider.select((s) => s.userModel));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
        actions: [
          if (cartItems.isNotEmpty)
            IconButton(
              tooltip: 'Clear cart',
              icon: const Icon(Icons.delete_sweep_outlined),
              onPressed: () => _confirmClearCart(context, ref),
            ),
        ],
      ),
      body: cartItems.isEmpty
          ? const _EmptyCartView()
          : _CartContent(
              cartItems: cartItems,
              isAuthenticated: isAuthenticated,
              userModel: userModel,
            ),
    );
  }

  Future<void> _confirmClearCart(BuildContext context, WidgetRef ref) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Clear Cart'),
        content: const Text('Remove all items from your cart?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Clear All'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      ref.read(cartProvider.notifier).clearCart();
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Cart cleared')),
        );
      }
    }
  }
}

// ─── Empty state ───────────────────────────────────────────────────────────

class _EmptyCartView extends StatelessWidget {
  const _EmptyCartView();

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.shopping_cart_outlined,
                size: 80, color: colors.onSurfaceVariant.withValues(alpha: 0.4)),
            const SizedBox(height: 16),
            Text(
              'Your cart is empty',
              style: textTheme.titleLarge,
            ),
            const SizedBox(height: 8),
            Text(
              'Browse our products and add items to get started.',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(color: colors.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Cart content (items + bottom bar) ─────────────────────────────────────

class _CartContent extends ConsumerWidget {
  final List<CartItem> cartItems;
  final bool isAuthenticated;
  final UserModel? userModel;

  const _CartContent({
    required this.cartItems,
    required this.isAuthenticated,
    required this.userModel,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cart = ref.read(cartProvider.notifier);
    final subtotal = cart.cartTotal;
    final savings = cart.totalSavings;
    final itemCount = cart.itemCount;

    return Column(
      children: [
        // Scrollable item list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            itemCount: cartItems.length,
            itemBuilder: (context, index) {
              final item = cartItems[index];
              return _DismissibleCartItem(
                item: item,
                index: index,
              );
            },
          ),
        ),

        // Bottom checkout bar
        _CheckoutBar(
          subtotal: subtotal,
          savings: savings,
          itemCount: itemCount,
          isAuthenticated: isAuthenticated,
          userModel: userModel,
          cartItems: cartItems,
        ),
      ],
    );
  }
}

// ─── Dismissible cart item ─────────────────────────────────────────────────

class _DismissibleCartItem extends ConsumerWidget {
  final CartItem item;
  final int index;

  const _DismissibleCartItem({
    required this.item,
    required this.index,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;

    return Semantics(
      label: '${item.name}, quantity ${item.quantity}, '
          '${CartScreen.formatPrice(item.lineTotal)}',
      child: Dismissible(
        key: ValueKey(item.name),
        direction: DismissDirection.endToStart,
        background: Container(
          alignment: Alignment.centerRight,
          padding: const EdgeInsets.only(right: 20),
          margin: const EdgeInsets.symmetric(vertical: 4),
          decoration: BoxDecoration(
            color: colors.errorContainer,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(Icons.delete_outlined, color: colors.error),
        ),
        confirmDismiss: (_) async => true,
        onDismissed: (_) {
          ref.read(cartProvider.notifier).removeFromCart(item);
          ScaffoldMessenger.of(context).clearSnackBars();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${item.name} removed'),
              action: SnackBarAction(
                label: 'Undo',
                onPressed: () {
                  ref.read(cartProvider.notifier).insertAt(index, item);
                },
              ),
            ),
          );
        },
        child: _CartItemCard(item: item),
      ),
    );
  }
}

// ─── Single cart item card ─────────────────────────────────────────────────

class _CartItemCard extends ConsumerWidget {
  final CartItem item;

  const _CartItemCard({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Product image
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.network(
                item.imageUrl,
                width: 80,
                height: 80,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  width: 80,
                  height: 80,
                  color: colors.surfaceContainerHighest,
                  child: Icon(Icons.image_not_supported_outlined,
                      color: colors.onSurfaceVariant),
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    item.name,
                    style: textTheme.titleSmall
                        ?.copyWith(fontWeight: FontWeight.w600),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),

                  // Prices
                  Row(
                    children: [
                      Text(
                        CartScreen.formatPrice(item.discountPrice),
                        style: textTheme.bodyMedium?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      if (item.hasDiscount) ...[
                        const SizedBox(width: 6),
                        Text(
                          CartScreen.formatPrice(item.salePrice),
                          style: textTheme.bodySmall?.copyWith(
                            decoration: TextDecoration.lineThrough,
                            color: colors.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ],
                  ),

                  if (item.hasDiscount) ...[
                    const SizedBox(height: 2),
                    Text(
                      '-${item.percentageReduction.toStringAsFixed(0)}%',
                      style: textTheme.labelSmall?.copyWith(
                        color: colors.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],

                  const SizedBox(height: 8),

                  // Quantity controls + remove
                  Row(
                    children: [
                      // Remove button
                      Semantics(
                        button: true,
                        label: 'Remove ${item.name}',
                        child: InkWell(
                          borderRadius: BorderRadius.circular(4),
                          onTap: () {
                            ref
                                .read(cartProvider.notifier)
                                .removeFromCart(item);
                          },
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 4, vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Icon(Icons.delete_outlined,
                                    size: 16, color: colors.error),
                                const SizedBox(width: 4),
                                Text(
                                  'Remove',
                                  style: textTheme.labelSmall
                                      ?.copyWith(color: colors.error),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const Spacer(),

                      // Quantity stepper
                      _QuantityStepper(item: item),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Quantity stepper ──────────────────────────────────────────────────────

class _QuantityStepper extends ConsumerWidget {
  final CartItem item;

  const _QuantityStepper({required this.item});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: colors.outlineVariant),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Semantics(
            button: true,
            label: 'Decrease quantity',
            child: SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.remove),
                onPressed: () {
                  if (item.quantity > 1) {
                    ref.read(cartProvider.notifier).decrementQuantity(item);
                  } else {
                    ref.read(cartProvider.notifier).removeFromCart(item);
                  }
                },
              ),
            ),
          ),
          SizedBox(
            width: 32,
            child: Text(
              '${item.quantity}',
              textAlign: TextAlign.center,
              style: textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.w600),
            ),
          ),
          Semantics(
            button: true,
            label: 'Increase quantity',
            child: SizedBox(
              width: 36,
              height: 36,
              child: IconButton(
                iconSize: 16,
                padding: EdgeInsets.zero,
                icon: const Icon(Icons.add),
                onPressed: () {
                  ref.read(cartProvider.notifier).incrementQuantity(item);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Checkout bottom bar ───────────────────────────────────────────────────

class _CheckoutBar extends StatelessWidget {
  final double subtotal;
  final double savings;
  final int itemCount;
  final bool isAuthenticated;
  final UserModel? userModel;
  final List<CartItem> cartItems;

  const _CheckoutBar({
    required this.subtotal,
    required this.savings,
    required this.itemCount,
    required this.isAuthenticated,
    required this.userModel,
    required this.cartItems,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;

    return Container(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
      decoration: BoxDecoration(
        color: colors.surface,
        border: Border(
          top: BorderSide(color: colors.outlineVariant, width: 0.5),
        ),
      ),
      child: SafeArea(
        top: false,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Summary row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Total ($itemCount ${itemCount == 1 ? 'item' : 'items'})',
                  style: textTheme.titleSmall,
                ),
                Text(
                  CartScreen.formatPrice(subtotal),
                  style: textTheme.titleMedium
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
              ],
            ),

            // Savings badge
            if (savings > 0) ...[
              const SizedBox(height: 4),
              Align(
                alignment: Alignment.centerRight,
                child: Text(
                  'You save ${CartScreen.formatPrice(savings)}',
                  style: textTheme.labelSmall?.copyWith(
                    color: colors.tertiary,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],

            const SizedBox(height: 12),

            // Checkout button
            FilledButton.icon(
              onPressed: () {
                if (isAuthenticated && userModel != null) {
                  _showOrderConfirmation(context);
                } else {
                  Navigator.pushNamed(context, '/loginScreen');
                }
              },
              icon: Icon(isAuthenticated
                  ? Icons.shopping_bag_outlined
                  : Icons.login),
              label: Text(isAuthenticated ? 'Order Now' : 'Log In to Order'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ─── Order confirmation before WhatsApp ──────────────────────

  void _showOrderConfirmation(BuildContext context) {
    final user = userModel!;

    showModalBottomSheet(
      context: context,
      useSafeArea: true,
      isScrollControlled: true,
      builder: (ctx) => Padding(
        padding: const EdgeInsets.fromLTRB(24, 24, 24, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Confirm Your Order',
              style: Theme.of(ctx)
                  .textTheme
                  .titleLarge
                  ?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),

            // Order summary
            ...cartItems.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Text(
                          '${item.name} x${item.quantity}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Text(
                        CartScreen.formatPrice(item.lineTotal),
                        style: const TextStyle(fontWeight: FontWeight.w600),
                      ),
                    ],
                  ),
                )),

            const Divider(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('Total',
                    style: TextStyle(fontWeight: FontWeight.bold)),
                Text(
                  CartScreen.formatPrice(subtotal),
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              'Order will be sent via WhatsApp to Zaloni Dental Hub.',
              style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                    color: Theme.of(ctx).colorScheme.onSurfaceVariant,
                  ),
            ),
            const SizedBox(height: 20),

            FilledButton.icon(
              onPressed: () {
                Navigator.pop(ctx);
                _checkout(context, cartItems, user);
              },
              icon: const Icon(Icons.send),
              label: const Text('Send Order via WhatsApp'),
              style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 48),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _checkout(
      BuildContext context, List<CartItem> items, UserModel user) async {
    if (items.isEmpty) return;

    final message = _constructWhatsAppMessage(items, user);
    final encoded = Uri.encodeComponent(message);
    const phone = '256772619555';
    final url = Uri.parse('https://wa.me/$phone?text=$encoded');

    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } else {
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text(
                  'WhatsApp is not installed. Please install WhatsApp to proceed.'),
              action: SnackBarAction(
                label: 'Install',
                onPressed: () {
                  launchUrl(
                    Uri.parse(
                      'https://play.google.com/store/apps/details?id=com.whatsapp',
                    ),
                    mode: LaunchMode.externalApplication,
                  );
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Could not open WhatsApp: $e')),
        );
      }
    }
  }

  String _constructWhatsAppMessage(
      List<CartItem> items, UserModel user) {
    final buffer = StringBuffer()
      ..writeln('Hello ZaloniDentalHub, I would like to place an order.')
      ..writeln()
      ..writeln('Name: ${user.fullName}')
      ..writeln('Phone: ${user.phoneNumber}')
      ..writeln()
      ..writeln('Cart Details:');

    for (final item in items) {
      buffer.writeln(
          '${item.name} - ${CartScreen.formatPrice(item.discountPrice)} x ${item.quantity}');
    }

    buffer.writeln();
    buffer.write(
        'Total: ${CartScreen.formatPrice(items.fold(0.0, (t, i) => t + i.lineTotal))}');

    return buffer.toString();
  }
}
