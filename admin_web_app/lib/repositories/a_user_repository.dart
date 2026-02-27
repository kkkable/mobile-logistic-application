import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter_dotenv/flutter_dotenv.dart';
import '../models/a_user_model.dart';

class UserRepository {
  final String _baseUrl = dotenv.env['BASE_URL']!;

  Future<List<User>> getUsers(String token) async {
    final response = await http.get(
      Uri.parse('$_baseUrl/api/web/customers'),
      headers: {'Authorization': 'Bearer $token'},
    );
    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to load users');
    }
  }
}
