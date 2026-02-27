import 'package:flutter/material.dart';
import '../repositories/a_order_repository.dart';
import '../models/a_order_model.dart';

class OrderProvider with ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();
  List<Order> _orders = [];
  List<Order> get orders => _orders;

  Future<void> fetchOrders(String token) async {
    try {
      _orders = await _orderRepository.getOrders(token);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
