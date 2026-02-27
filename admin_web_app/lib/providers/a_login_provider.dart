import 'package:flutter/material.dart';
import '../repositories/a_login_repository.dart';

class LoginProvider with ChangeNotifier {
  final LoginRepository _loginRepository = LoginRepository();
  String? _token;
  String? _username; 
  
  bool get isAuthenticated => _token != null;
  String? get token => _token;
  String? get username => _username; 

  Future<void> login(String inputUsername, String password) async {
    try {
      _token = await _loginRepository.login(inputUsername, password);
      _username = inputUsername; 
      
      notifyListeners();
    } catch (e) {
      print(e);
      rethrow;
    }
  }

  void logout() {
    _token = null;
    _username = null;
    notifyListeners();
  }
}