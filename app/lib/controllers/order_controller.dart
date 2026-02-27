import 'package:flutter/material.dart';
import '../models/order.dart';
import '../repositories/order_repository.dart';

class OrderController extends ChangeNotifier {
  final OrderRepository _orderRepository = OrderRepository();
  List<Order> orders = [];

  Future<void> placeAndDistributeOrder({
    required String pickupLocation,
    required String dropoffLocation,
    required String token,
    required int userId,
    required double weight,
  }) async {
    try {
      await _orderRepository.placeAndDistributeOrder(
        pickupLocation: pickupLocation,
        dropoffLocation: dropoffLocation,
        token: token,
        userId: userId,
        weight: weight,
      );
      
      await fetchOrders(token: token, userId: userId);
    } catch (e) {
      print(e);
      throw Exception('Error placing order: $e');
    }
  }

  Future<void> fetchOrders({required String token, required int userId}) async {
    try {
      orders = await _orderRepository.fetchOrders(token: token, userId: userId);
      notifyListeners();
    } catch (e) {
      print(e);
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<bool> checkIfRated(int orderId, String token) async {
    return await _orderRepository.checkIfRated(orderId, token);
  }
}