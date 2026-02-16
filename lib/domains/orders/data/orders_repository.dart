import 'package:dominium/core/persistence/hive_bootstrap.dart';
import 'package:dominium/domains/orders/data/order_item.dart';
import 'package:hive/hive.dart';

class OrdersRepository {
  OrdersRepository(this._box);

  final Box<Map> _box;

  factory OrdersRepository.fromHive() {
    return OrdersRepository(Hive.box<Map>(HiveBootstrap.ordersBox));
  }

  List<OrderItem> all() => _box.values.map(OrderItem.fromMap).toList();

  Future<void> upsert(OrderItem order) => _box.put(order.id, order.toMap());

  Future<void> delete(String id) => _box.delete(id);
}
