import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/d_order.dart';
import 'package:flutter/foundation.dart';

Map<String, dynamic> _parseAndDecode(String responseBody) {
  return jsonDecode(responseBody);
}

class OrderRepository {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';

  Future<List<Order>> fetchDriverOrders({required String token, required int driverId}) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/orders/driver/$driverId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((order) => Order.fromJson(order)).toList();
      } else {
        throw Exception('Failed to fetch orders: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error fetching orders: $e');
    }
  }

  Future<void> updateDriverLocation({required String token, required double latitude, required double longitude}) async {
     await http.post(
        Uri.parse('$_baseUrl/api/drivers/location'),
        headers: {'Authorization': 'Bearer $token', 'Content-Type': 'application/json'},
        body: jsonEncode({'latitude': latitude, 'longitude': longitude}),
      );
  }

  Future<Map<String, dynamic>> fetchOptimizedRoute({required String token, required int driverId}) async {
     final response = await http.get(
        Uri.parse('$_baseUrl/api/drivers/$driverId/route'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (response.statusCode == 200) {
        return await compute(_parseAndDecode, response.body);
      } else {
        // return empty to prevent crash
        return {'order': [], 'polylines': []};
      }
  }

  Future<void> removeRouteNode({required String token, required String nodeId}) async {
     try {
       await http.post(
          Uri.parse('$_baseUrl/api/drivers/arrive_node'),
          headers: {
            'Authorization': 'Bearer $token',
            'Content-Type': 'application/json'
          },
          body: jsonEncode({'node_id': nodeId}),
       );
     } catch (e) {
       print("Error removing route node: $e");
     }
  }

  Future<http.StreamedResponse> finishOrder({required String token, required int orderId, required String imagePath, required double lat, required double lng}) async {
      var request = http.MultipartRequest('POST', Uri.parse('$_baseUrl/api/orders/$orderId/finish'));
      request.headers['Authorization'] = 'Bearer $token';
      request.fields['lat'] = lat.toString();
      request.fields['lng'] = lng.toString();
      request.files.add(await http.MultipartFile.fromPath('photo', imagePath));
      return await request.send();
  }
}