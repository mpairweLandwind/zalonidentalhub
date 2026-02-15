import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:zalonidentalhub/models/cart_item.dart';

class Cart extends Notifier<List<CartItem>> {
  @override
  List<CartItem> build() => [];

  void addToCart(CartItem item) {
    final existingIndex = state.indexWhere((i) => i.name == item.name);
    if (existingIndex >= 0) {
      final updated = [...state];
      updated[existingIndex] = updated[existingIndex].copyWith(
        quantity: updated[existingIndex].quantity + item.quantity,
      );
      state = updated;
    } else {
      state = [...state, item];
    }
  }

  void removeFromCart(CartItem item) {
    state = state.where((i) => i.name != item.name).toList();
  }

  /// Re-insert a previously removed item at its original index.
  void insertAt(int index, CartItem item) {
    final updated = [...state];
    updated.insert(index.clamp(0, updated.length), item);
    state = updated;
  }

  void incrementQuantity(CartItem item) {
    state = state.map((i) {
      if (i.name == item.name) {
        return i.copyWith(quantity: i.quantity + 1);
      }
      return i;
    }).toList();
  }

  void decrementQuantity(CartItem item) {
    state = state.map((i) {
      if (i.name == item.name && i.quantity > 1) {
        return i.copyWith(quantity: i.quantity - 1);
      }
      return i;
    }).toList();
  }

  void clearCart() {
    state = [];
  }

  double get cartTotal {
    return state.fold(
        0, (total, item) => total + item.lineTotal);
  }

  double get totalSavings {
    return state.fold(
        0, (total, item) => total + item.lineSavings);
  }

  int get itemCount {
    return state.fold(0, (total, item) => total + item.quantity);
  }
}

final cartProvider = NotifierProvider<Cart, List<CartItem>>(Cart.new);
