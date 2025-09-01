import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:zalonidentalhub/models/cart_item.dart';
import 'package:zalonidentalhub/models/cart_model.dart';
import 'package:zalonidentalhub/models/user_model.dart';
import 'package:zalonidentalhub/providers/authprovider.dart';

class CartScreen extends ConsumerStatefulWidget {
  const CartScreen({super.key, required List cartItems, required int cartTotal, required Cart cart, required user});

  @override
  ConsumerState<CartScreen> createState() => _CartScreenState();
}

class _CartScreenState extends ConsumerState<CartScreen> {
  // Helper function to format numbers with commas
String _formatPrice(double price) {
    return 'UGX ${price.toStringAsFixed(2).replaceAllMapped(
          RegExp(r'(\d{1,3})(?=(\d{3})+(?!\d))'),
          (Match m) => '${m[1]},',
        )}';
  }

  @override
  Widget build(BuildContext context) {
    final cartItems = ref.watch(cartProvider);
    final auth = ref.watch(authProvider);
    final user = auth.userModel;
    final isLoggedIn = ref.watch(authProvider).isAuthenticated;
    final double subtotal = cartItems.fold(
      0.0,
      (total, item) => total + (item.discountPrice * item.quantity),
    );

    return Scaffold(
      appBar: AppBar(
        title: const Text('Cart'),
      ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          if (isLoggedIn && user != null)
            Padding(
              padding: const EdgeInsets.all(16.0),
              child: Text(
                'Welcome ${user.firstName} ${user.lastName}',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.blue,
                ),
              ),
            ),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 16.0),
            child: Divider(),
          ),
          Expanded(
            child: ListView(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Cart Summary',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Subtotal: ${_formatPrice(subtotal)}',
                        style: const TextStyle(
                          fontSize: 16,
                          color: Colors.grey,
                        ),
                      ),
                    ],
                  ),
                ),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: cartItems.length,
                  itemBuilder: (context, index) {
                    final CartItem item = cartItems[index];
                    return Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Card(
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12.0),
                        ),
                        elevation: 5,
                        shadowColor: Colors.grey.withAlpha((0.3 * 255).toInt()),
                        child: Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              ClipRRect(
                                borderRadius: BorderRadius.circular(8.0),
                                child: Image.network(
                                  item.imageUrl,
                                  width: 80,
                                  height: 80,
                                  fit: BoxFit.cover,
                                  errorBuilder: (context, error, stackTrace) =>
                                      const Icon(Icons.error, size: 80),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      item.name,
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 14,
                                      ),
                                      maxLines: 2,
                                      overflow: TextOverflow.ellipsis,
                                    ),
                                    const SizedBox(height: 4),
                                    Row(
                                      children: [
                                        Text(
                                          _formatPrice(item.discountPrice),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                        Text(
                                          _formatPrice(item.salePrice),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            decoration: TextDecoration.lineThrough,
                                            color: Colors.grey,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      '-${item.percentageReduction.toStringAsFixed(0)}%',
                                      style: const TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold,
                                        color: Colors.green,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    const Text(
                                      'ZaloniDentalHub Express',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.blue,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Row(
                                      children: [
                                        TextButton.icon(
                                          onPressed: () {
                                            ref
                                                .read(cartProvider.notifier)
                                                .removeFromCart(item);
                                          },
                                          icon: const Icon(
                                            Icons.delete,
                                            color: Colors.red,
                                            size: 16,
                                          ),
                                          label: const Text(
                                            'Remove',
                                            style: TextStyle(
                                              color: Colors.red,
                                              fontSize: 12,
                                            ),
                                          ),
                                        ),
                                        const Spacer(),
                                        Row(
                                          children: [
                                            IconButton(
                                              icon: const Icon(Icons.remove, size: 18),
                                              onPressed: () {
                                                if (item.quantity > 1) {
                                                  ref
                                                      .read(cartProvider.notifier)
                                                      .decrementQuantity(item);
                                                } else {
                                                  ref
                                                      .read(cartProvider.notifier)
                                                      .removeFromCart(item);
                                                }
                                              },
                                            ),
                                            Text(
                                              item.quantity.toString(),
                                              style: const TextStyle(
                                                fontSize: 14,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            IconButton(
                                              icon: const Icon(Icons.add, size: 18),
                                              onPressed: () => ref
                                                  .read(cartProvider.notifier)
                                                  .incrementQuantity(item),
                                            ),
                                          ],
                                        ),
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
                  },
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.all(16.0),
            decoration: const BoxDecoration(
              border: Border(
                top: BorderSide(color: Colors.grey, width: 0.5),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    const Text(
                      'Total:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      _formatPrice(subtotal),
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                ElevatedButton(
                  onPressed: () {
                    if (isLoggedIn) {
                      _checkout(cartItems, user!);
                    } else {
                      Navigator.pushNamed(context, '/accountScreen');
                    }
                  },
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12.0),
                    ),
                  ),
                  child: const Text('Order Now'),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _checkout(List<CartItem> cartItems, UserModel user) async {
    if (cartItems.isEmpty) return;

    final String message = _constructWhatsAppMessage(cartItems, user);
    final String encodedMessage = Uri.encodeComponent(message);
    const String businessPhoneNumber = '256772619555';
    final Uri whatsappUrl = Uri.parse('https://wa.me/$businessPhoneNumber?text=$encodedMessage');

    try {
      if (await canLaunchUrl(whatsappUrl)) {
        await launchUrl(whatsappUrl);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: const Text('WhatsApp is not installed. Please install WhatsApp to proceed.'),
              action: SnackBarAction(
                label: 'Install WhatsApp',
                onPressed: () {
                  final Uri playStoreUrl = Uri.parse(
                    'https://play.google.com/store/apps/details?id=com.whatsapp',
                  );
                  launchUrl(playStoreUrl);
                },
              ),
            ),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error: $e')),
        );
      }
    }
  }

  String _constructWhatsAppMessage(List<CartItem> cartItems, UserModel user) {
    String message = "Hello ZaloniDentalHub, I would like to place an order.\n\n";
    message += "Name: ${user.firstName} ${user.lastName}\n";
    message += "Phone: ${user.phoneNumber}\n\n";
    message += "Cart Details:\n";

    for (var item in cartItems) {
      message += "${item.name} - ${_formatPrice(item.discountPrice)} x ${item.quantity}\n";
    }

    message += "\nTotal: ${_formatPrice(cartItems.fold(0.0, (total, item) => total + (item.discountPrice * item.quantity)))}";

    return message;
  }
}
