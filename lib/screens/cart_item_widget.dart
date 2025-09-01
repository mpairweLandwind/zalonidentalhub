import 'package:flutter/material.dart';
import 'package:zalonidentalhub/models/product.dart';


class CartItemWidget extends StatelessWidget {
  final Product product;
  final int quantity;
  final Function(int) onQuantityChanged;

  const CartItemWidget({
    super.key,
    required this.product,
    required this.quantity,
    required this.onQuantityChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.all(8),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            Image.network(
              product.imageUrl,
              width: 100,
              height: 100,
              fit: BoxFit.cover,
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Text(product.name,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                  )),
            ),
            IconButton(
              icon: const Icon(Icons.remove),
              onPressed: () {
                if (quantity > 1) {
                  onQuantityChanged(quantity - 1);
                }
              },
            ),
            Text('$quantity'),
            IconButton(
              icon: const Icon(Icons.add),
              onPressed: () {
                onQuantityChanged(quantity + 1);
              },
            ),
          ],
        ),
      ),
    );
  }
}