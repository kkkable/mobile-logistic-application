import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/a_driver_model.dart';
import '../models/a_rating_model.dart';

class DriverRepository {
  final String _baseUrl = dotenv.env['BASE_URL'] ?? 'http://localhost:8080';

  Future<List<Driver>> getDrivers(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/web/drivers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => Driver.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load drivers');
    }
  }

  Future<List<Rating>> getAllRatings(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/api/web/ratings'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final List<dynamic> data = jsonDecode(response.body);
        return data.map((json) => Rating.fromJson(json)).toList();
      } else {
        print("Warning fetching ratings: ${response.statusCode}");
        return [];
      }
    } catch (e) {
      print("Error fetching ratings: $e");
      return [];
    }
  }
}