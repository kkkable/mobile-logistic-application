import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/d_driver.dart';


class DriverRepository {
  final String baseUrl = dotenv.env['BASE_URL']!;

  Future<Driver> fetchDriver(int driverId, String token) async {
    final response = await http.get(
      Uri.parse('$baseUrl/api/drivers/$driverId/details'),
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      return Driver.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load driver');
    }
  }

  
}
