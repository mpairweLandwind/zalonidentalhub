import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/cart_model.dart';

class CartIconWithBadge extends ConsumerWidget {
  const CartIconWithBadge({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final itemCount = ref.watch(cartProvider).fold(0, (total, item) => total + item.quantity);

    return GestureDetector(
      onTap: () {
        Navigator.pushNamed(context, '/CartScreen');
      },
      child: Stack(
        alignment: Alignment.topRight,
        children: [
          IconButton(
            icon: const Icon(Icons.shopping_cart),
            onPressed: () {
              Navigator.pushNamed(context, '/CartScreen');
            },
          ),
          if (itemCount > 0)
            Positioned(
              right: 0,
              child: Container(
                padding: const EdgeInsets.all(1),
                decoration: BoxDecoration(
                  color: Colors.red,
                  borderRadius: BorderRadius.circular(6),
                ),
                constraints: const BoxConstraints(
                  minWidth: 12,
                  minHeight: 12,
                ),
                child: Text(
                  '$itemCount',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                  ),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
