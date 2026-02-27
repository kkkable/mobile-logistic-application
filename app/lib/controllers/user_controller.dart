import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class User {
  final String name;
  final String email;
  final String phone;
  final String address;
  final String username;

  User({
    required this.name,
    required this.email,
    required this.phone,
    required this.address,
    required this.username,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    return User(
      name: json['name'] as String,
      email: json['email'] as String,
      phone: json['phone'] as String,
      address: json['address'] as String,
      username: json['username'] as String,
    );
  }
}

class UserController extends ChangeNotifier {
  User? user;

  Future<void> fetchUser(int userId, String token) async {
    final baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/users/$userId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        user = User.fromJson(jsonDecode(response.body));
        notifyListeners();
      } else {
        developer.log('Failed to fetch user: ${response.body}', name: 'UserController');
      }
    } catch (e) {
      developer.log('Error fetching user: $e', name: 'UserController');
    }
  }
}