import 'dart:convert';
import 'package:http/http.dart' as http;
import 'base_service.dart';

class AuthService extends BaseService {
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${BaseService.baseUrl}/sign-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': email, 'password': password}),
    );

    final responseBody = jsonDecode(response.body);
    final data = BaseService.handleResponse(responseBody);

    if (response.statusCode == 200) {
      if (data['tokens'] != null) {
        await BaseService.saveToken(data['tokens']['refreshToken']);
      }
      return data;
    } else {
      throw Exception('Login failed: ${data['message']}');
    }
  }

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('${BaseService.baseUrl}/sign-up'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final responseBody = jsonDecode(response.body);
    final data = BaseService.handleResponse(responseBody);

    if (response.statusCode == 200) {
      if (data['tokens'] != null) {
        await BaseService.saveToken(data['tokens']['refreshToken']);
      }
      return data;
    } else {
      throw Exception('Registration failed: ${data['message']}');
    }
  }

  static Future<void> logout() async {
    await BaseService.clearToken();
  }
}
