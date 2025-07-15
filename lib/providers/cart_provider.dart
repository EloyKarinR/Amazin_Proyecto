import 'package:flutter/foundation.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../models/cart_item.dart';
import '../models/product.dart';
import 'dart:collection'; // Importar para UnmodifiableListView

class CartProvider with ChangeNotifier {
  static const String _cartBoxName = 'cartItems';
  late Box<CartItem> _cartBox;

  CartProvider() {
    _openBox();
  }

  Future<void> _openBox() async {
    // Registrar adaptadores generados por build_runner
    if (!Hive.isAdapterRegistered(0)) {
       Hive.registerAdapter(CartItemAdapter());
    }
     if (!Hive.isAdapterRegistered(1)) {
       Hive.registerAdapter(ProductAdapter());
    }

    // Abrir o crear la caja
    _cartBox = await Hive.openBox<CartItem>(_cartBoxName);
    // Limpiar la caja para depurar problemas de deserialización con datos antiguos
    // await _cartBox.clear();

    // Cargar ítems existentes
    _items.clear();
    for (var item in _cartBox.values) {
      // Asegurarnos de que isSelected no sea null al cargarlo en el provider
      _items[item.product.id] = CartItem(
        product: item.product,
        quantity: item.quantity,
        isSelected: item.isSelected ?? true, // Si es null al leer, lo hacemos true
      );
    }
    notifyListeners();
  }

  final Map<String, CartItem> _items = {}; // Hacer _items final

  UnmodifiableListView<CartItem> get items => UnmodifiableListView(_items.values);

  int get itemCount => _items.length;

  double get totalAmount {
    return _items.values.fold(0.0, (sum, item) => sum + item.totalPrice);
  }

  double get selectedTotalAmount {
    double total = 0.0;
    for (var item in _items.values) {
      if (item.isSelected == true) {
        total += item.totalPrice;
      }
    }
    return total;
  }

  void addItem(Product product, int quantity) {
    if (_items.containsKey(product.id)) {
      // Si el producto ya está en el carrito, actualizamos la cantidad
      _items.update(
        product.id,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: existingItem.quantity + quantity,
        ),
      );
    } else {
      // Si el producto no está en el carrito, lo agregamos
      _items.putIfAbsent(
        product.id,
        () => CartItem(
          product: product,
          quantity: quantity,
        ),
      );
    }
    _cartBox.put(product.id, _items[product.id]!);
    notifyListeners();
  }

  void removeItem(String productId) {
    _items.remove(productId);
    _cartBox.delete(productId);
    notifyListeners();
  }

  void updateQuantity(String productId, int quantity) {
    if (!_items.containsKey(productId)) return;
    if (quantity <= 0) {
      removeItem(productId);
    } else {
      _items.update(
        productId,
        (existingItem) => CartItem(
          product: existingItem.product,
          quantity: quantity,
        ),
      );
       _cartBox.put(productId, _items[productId]!);
    }
    notifyListeners();
  }

  void clear() {
    _items.clear();
    _cartBox.clear();
    notifyListeners();
  }

  void toggleItemSelection(String productId) {
    if (_items.containsKey(productId)) {
      final currentItem = _items[productId]!;
      final updatedItem = currentItem.copyWith(isSelected: !(currentItem.isSelected ?? false));
      _items[productId] = updatedItem;
      // Guardar el cambio en Hive
      _cartBox.put(productId, updatedItem);
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _cartBox.close();
    super.dispose();
  }
} 