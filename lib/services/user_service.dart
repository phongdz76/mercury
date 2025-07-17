import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../constants/app_constants.dart';
import 'base_service.dart';

class UserService extends BaseService {
  static Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}/me'),
      headers: await BaseService.getHeaders(),
    );

    final responseBody = jsonDecode(response.body);
    final data = BaseService.handleResponse(responseBody);

    if (response.statusCode == 200) {
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load current user: ${response.body}');
    }
  }

  static String getUserAvatarUrl(String userId) {
    return '${BaseService.baseUrl}/users/$userId/avatar';
  }

  static Future<User> getUserById(String userId) async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}/users/$userId'),
      headers: await BaseService.getHeaders(),
    );

    final responseBody = jsonDecode(response.body);
    final data = BaseService.handleResponse(responseBody);

    if (response.statusCode == 200) {
      return User.fromJson(data['user'] ?? data);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  static Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}${ApiConstants.profile}'),
      headers: await BaseService.getHeaders(),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final userData = responseBody['data']['user'];
      return User.fromJson(userData);
    } else {
      throw Exception('Failed to load profile: ${response.body}');
    }
  }

  static Future<User> updateProfile({
    required String username,
    required String email,
    String? fullName,
    String? avatar,
  }) async {
    final body = {'username': username, 'email': email};

    if (fullName != null) body['fullName'] = fullName;
    if (avatar != null) body['avatar'] = avatar;

    final response = await http.patch(
      Uri.parse('${BaseService.baseUrl}${ApiConstants.profile}'),
      headers: await BaseService.getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final userData = responseBody['data']['user'];
      return User.fromJson(userData);
    } else {
      final errorData = jsonDecode(response.body);
      throw Exception(
        'Failed to update profile: ${errorData['message'] ?? response.body}',
      );
    }
  }

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) async {
    final response = await http.put(
      Uri.parse('${BaseService.baseUrl}${ApiConstants.changePassword}'),
      headers: await BaseService.getHeaders(),
      body: jsonEncode({
        'currentPassword': currentPassword,
        'newPassword': newPassword,
        'confirmPassword': confirmPassword,
      }),
    );

    if (response.statusCode != 200) {
      final errorData = jsonDecode(response.body);
      throw Exception(
        'Failed to change password: ${errorData['message'] ?? response.body}',
      );
    }
  }
}
