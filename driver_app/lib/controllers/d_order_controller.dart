import 'package:flutter/material.dart';
import '../models/d_order.dart';
import '../repositories/d_order_repository.dart';

class OrderController extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();
  List<Order> orders = [];

  Future<void> fetchOrders({required String token, required int driverId}) async {
    try {
      orders = await _orderRepository.fetchDriverOrders(token: token, driverId: driverId);
      notifyListeners();
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }
}