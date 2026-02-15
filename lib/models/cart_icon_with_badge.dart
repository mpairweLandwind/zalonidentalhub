import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/cart_model.dart';

class CartIconWithBadge extends ConsumerWidget {
  const CartIconWithBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount =
        ref.watch(cartProvider).fold(0, (total, item) => total + item.quantity);

    return Semantics(
      label: 'Shopping cart, $itemCount items',
      button: true,
      child: IconButton(
        icon: Badge(
          isLabelVisible: itemCount > 0,
          label: Text('$itemCount'),
          child: const Icon(Icons.shopping_cart),
        ),
        onPressed: () {
          Navigator.pushNamed(context, '/CartScreen');
        },
      ),
    );
  }
}
