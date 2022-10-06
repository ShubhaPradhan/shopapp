import 'dart:convert';
import 'package:flutter/material.dart';

import 'package:http/http.dart' as http;

class CartItem {
  final String cartId;
  final String id;
  final String title;
  final int quantity;
  final double price;

  CartItem({
    @required this.cartId,
    @required this.id,
    @required this.title,
    @required this.quantity,
    @required this.price,
  });
}

class Cart with ChangeNotifier {
  Map<String, CartItem> _items = {};

  Map<String, CartItem> get items {
    return {..._items};
  }

  int get itemCount {
    return _items == null ? 0 : _items.length;
  }

  double get totalAmount {
    var total = 0.0;
    _items.forEach((key, cartItem) {
      total += cartItem.price * cartItem.quantity;
    });
    return total;
  }

  String getCartId(String productId) {
    String cartId;
    _items.entries.forEach((element) {
      print("shubha");
      if (element.value.id == productId) {
        cartId = element.value.cartId;
      }
    });
    return cartId;
  }

  Future<void> fetchAndSetCart() async {
    final url = Uri.parse(
        'https://shopapp-c7c23-default-rtdb.asia-southeast1.firebasedatabase.app/carts.json');
    try {
      final response = await http.get(url);
      final extractedData = json.decode(response.body) as Map<String, dynamic>;
      final Map<String, CartItem> loadedCarts = {};
      if (extractedData == null) {
        return;
      }
      extractedData.forEach((cartId, cartData) {
        loadedCarts.putIfAbsent(
            cartData['id'],
            () => CartItem(
                  cartId: cartId,
                  id: cartData['id'],
                  title: cartData['title'],
                  quantity: cartData['quantity'],
                  price: cartData['price'],
                ));
      });
      _items = loadedCarts;
      // notifyListeners(); This is not rendering the cartItems (don't know why)
    } catch (error) {
      throw error;
    }
  }

  Future<void> addNewItem(
    String productId,
    double price,
    String title,
  ) async {
    final url = Uri.parse(
        'https://shopapp-c7c23-default-rtdb.asia-southeast1.firebasedatabase.app/carts.json');
    try {
      final response = await http.post(
        url,
        body: json.encode({
          'id': productId,
          'title': title,
          'price': price,
          'quantity': 1,
        }),
      );
      _items.putIfAbsent(
        productId,
        () => CartItem(
          cartId: json.decode(response.body)['name'],
          id: productId,
          title: title,
          price: price,
          quantity: 1,
        ),
      );
      notifyListeners();
    } catch (error) {
      throw error;
    }
  }

  Future<void> updateCartItem(
    String cartId,
    String productId,
    double price,
    String title,
  ) async {
    final url = Uri.parse(
        'https://shopapp-c7c23-default-rtdb.asia-southeast1.firebasedatabase.app/carts/$cartId.json');
    await http.patch(
      url,
      body: json.encode({
        'id': productId,
        'title': title,
        'price': price,
        'quantity': _items[productId].quantity + 1,
      }),
    );
    _items.update(
      productId,
      (existingCartItem) => CartItem(
        cartId: existingCartItem.cartId,
        id: existingCartItem.id,
        title: existingCartItem.title,
        quantity: existingCartItem.quantity + 1,
        price: existingCartItem.price,
      ),
    );
    notifyListeners();
  }

  Future<void> addItem(
    String cartID,
    String productId,
    double price,
    String title,
  ) async {
    if (_items.containsKey(productId)) {
      updateCartItem(cartID, productId, price, title);
    } else {
      addNewItem(productId, price, title);
    }
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    notifyListeners();
  }

  void removeSingleItem(String productId) {
    if (!_items.containsKey(productId)) {
      return;
    }
    if (_items[productId].quantity > 1) {
      _items.update(
        productId,
        (existingCartItem) => CartItem(
          cartId: existingCartItem.cartId,
          id: existingCartItem.id,
          title: existingCartItem.title,
          quantity: existingCartItem.quantity - 1,
          price: existingCartItem.price,
        ),
      );
    } else {
      _items.remove(productId);
    }
    notifyListeners();
  }

  void clear() {
    _items = {};
    notifyListeners();
  }
}
