import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';

class EditRepository {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<Map<String, dynamic>> getRecord(String table, int id, String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/web/$table/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Failed to load record');
    }
  }

  Future<void> addRecord(String table, Map<String, dynamic> data, String token) async {
    final response = await http.post(
      Uri.parse('$_baseUrl/api/web/$table'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 201) {
      throw Exception('Failed to add record');
    }
  }

  Future<void> updateRecord(String table, int id, Map<String, dynamic> data, String token) async {
    final response = await http.put(
      Uri.parse('$_baseUrl/api/web/$table/$id'),
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token',
      },
      body: jsonEncode(data),
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to update record');
    }
  }

  Future<void> deleteRecord(String table, int id, String token) async {
    final response = await http.delete(
      Uri.parse('$_baseUrl/api/web/$table/$id'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode != 200) {
      throw Exception('Failed to delete record');
    }
  }
}
