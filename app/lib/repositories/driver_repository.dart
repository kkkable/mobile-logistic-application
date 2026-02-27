import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart'; 
import '../models/driver.dart';

class DriverRepository {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';

  Future<Driver> fetchDriverDetails(int driverId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/drivers/$driverId'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return Driver(
        driverId: driverId,
        name: data['name'] ?? 'Unknown Driver',
        avgRating: 0.0,
      );
    } else {
      throw Exception('Failed to load driver details: ${response.statusCode}');
    }
  }

  Future<double> fetchDriverAverageRating(int driverId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/drivers/$driverId/average_rating'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      return data['average_rating'] is String
          ? double.tryParse(data['average_rating']) ?? 0.0
          : (data['average_rating'] ?? 0.0) as double;
    }
    return 0.0;
  }
}