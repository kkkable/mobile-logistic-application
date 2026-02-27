import 'package:flutter_dotenv/flutter_dotenv.dart'; 

class UserRepository {
  final String baseUrl = dotenv.env['BASE_URL'] ?? 'http://10.0.2.2:8080';
}