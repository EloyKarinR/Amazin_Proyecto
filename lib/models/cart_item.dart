import 'package:hive/hive.dart';
import 'product.dart';

part 'cart_item.g.dart';

@HiveType(typeId: 0)
class CartItem extends HiveObject {
  @HiveField(0)
  final Product product;
  @HiveField(1)
  final int quantity;
  @HiveField(2)
  bool? isSelected;

  CartItem({
    required this.product,
    required this.quantity,
    this.isSelected,
  }) {
    isSelected ??= true;
  }

  double get totalPrice => product.price * quantity;

  CartItem copyWith({
    Product? product,
    int? quantity,
    bool? isSelected,
  }) {
    return CartItem(
      product: product ?? this.product,
      quantity: quantity ?? this.quantity,
      isSelected: isSelected ?? this.isSelected,
    );
  }
} 