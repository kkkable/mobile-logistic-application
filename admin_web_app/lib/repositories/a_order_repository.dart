import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/a_order_model.dart';

class OrderRepository {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

  Future<List<Order>> getOrders(String token) async {
    try {
      print("📡 Fetching orders from: $_baseUrl/api/web/orders");
      
      final response = await http.get(
        Uri.parse('$_baseUrl/api/web/orders'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        print("Orders fetched: ${data.length}");
        return data.map((json) => Order.fromJson(json)).toList();
      } else {
        print("Server Error: ${response.statusCode} - ${response.body}");
        throw Exception('Failed to load orders: ${response.statusCode}');
      }
    } catch (e) {
      print("Repository Error: $e");
      return []; 
    }
  }
}