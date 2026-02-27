import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import '../models/order.dart';

class OrderRepository {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';

  Future<void> placeAndDistributeOrder({
    required String pickupLocation,
    required String dropoffLocation,
    required String token,
    required int userId,
    required double weight,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/orders/distribute'),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'pickup_location': pickupLocation,
          'dropoff_location': dropoffLocation,
          'status': 'pending',
          'weight': weight,
        }),
      );
      if (response.statusCode != 200) {
        throw Exception('Failed to place and distribute order: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error in placeAndDistributeOrder: $e');
    }
  }

  Future<List<Order>> fetchOrders({required String token, required int userId}) async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/orders'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(const Duration(seconds: 10));
      
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((order) => Order(
          orderId: order['order_id'],
          userId: order['user_id'],
          driverId: order['driver_id'],
          pickupLocation: order['pickup_location'],
          dropoffLocation: order['dropoff_location'],
          status: order['status'],
          weight: order['weight'] != null ? double.parse(order['weight'].toString()) : null,
        )).toList();
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<bool> checkIfRated(int orderId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/orders/check/$orderId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body)['rated'];
    }
    return false;
  }
}