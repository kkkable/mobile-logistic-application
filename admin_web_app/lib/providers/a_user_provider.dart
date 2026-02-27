import 'package:flutter/material.dart';
import '../repositories/a_user_repository.dart';
import '../models/a_user_model.dart';

class UserProvider with ChangeNotifier {
  final UserRepository _userRepository = UserRepository();
  List<User> _users = [];
  List<User> get users => _users;

  Future<void> fetchUsers(String token) async {
    try {
      _users = await _userRepository.getUsers(token);
      notifyListeners();
    } catch (e) {
      print(e);
    }
  }
}
