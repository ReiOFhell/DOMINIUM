import 'package:dominium/domains/orders/data/order_item.dart';
import 'package:dominium/domains/orders/data/orders_repository.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final ordersRepositoryProvider = Provider<OrdersRepository>((_) => OrdersRepository.fromHive());

final ordersProvider = StateNotifierProvider<OrdersController, List<OrderItem>>(
  (ref) => OrdersController(ref.read(ordersRepositoryProvider)),
);

class OrdersController extends StateNotifier<List<OrderItem>> {
  OrdersController(this._repo) : super(_repo.all());

  final OrdersRepository _repo;

  Future<void> save(OrderItem item) async {
    await _repo.upsert(item);
    state = _repo.all();
  }

  Future<void> remove(String id) async {
    await _repo.delete(id);
    state = _repo.all();
  }
}
