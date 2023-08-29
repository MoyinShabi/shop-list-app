import 'package:shop_list_app/models/category.dart';

class ShopItem {
  const ShopItem({
    required this.id,
    required this.name,
    required this.quantity,
    required this.category,
  });

  final String id;
  final String name;
  final int quantity;
  final Category category;
}
