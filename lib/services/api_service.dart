import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../constants/app_constants.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;

  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints
  static Future<Map<String, dynamic>> login(
    String email,
    String password,
  ) async {
    final response = await http.post(
      Uri.parse('$baseUrl/sign-in'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({'identifier': email, 'password': password}),
    );

    final responseBody = jsonDecode(response.body);
    final data = responseBody['data'] ?? responseBody;
    if (response.statusCode == 200) {
      if (data['tokens'] != null) {
        await saveToken(data['tokens']['refreshToken']);
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
      Uri.parse('$baseUrl/sign-up'),
      headers: {'Content-Type': 'application/json'},
      body: jsonEncode({
        'username': username,
        'email': email,
        'password': password,
      }),
    );

    final responseBody = jsonDecode(response.body);
    final data = responseBody['data'] ?? responseBody;

    if (response.statusCode == 200) {
      if (data['tokens'] != null) {
        await saveToken(data['tokens']['refreshToken']);
      }
      return data;
    } else {
      throw Exception('Registration failed: ${data['message']}');
    }
  }

  // Conversation endpoints
  static Future<List<Conversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations'),
      headers: await getHeaders(),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Fix: Handle the nested structure properly
      final data = responseBody['data'];
      if (data != null && data['conversations'] != null) {
        final conversations = data['conversations'] as List<dynamic>;
        return conversations
            .map((json) => Conversation.fromJson(json))
            .toList();
      } else {
        // Fallback for direct array response
        final conversations = responseBody as List<dynamic>;
        return conversations
            .map((json) => Conversation.fromJson(json))
            .toList();
      }
    } else {
      throw Exception('Failed to load conversations: ${response.body}');
    }
  }

  static Future<Conversation> getConversation(String id) async {
    final response = await http.get(
      Uri.parse('$baseUrl/conversations/$id'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load conversation: ${response.body}');
    }
  }

  static Future<Conversation> createConversation({
    required String type,
    required List<String> participants,
    String? title,
    String? description,
  }) async {
    final response = await http.post(
      Uri.parse('$baseUrl/conversations'),
      headers: await getHeaders(),
      body: jsonEncode({
        'type': type,
        'participants': participants,
        'title': title,
        'description': description,
      }),
    );

    if (response.statusCode == 201) {
      return Conversation.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to create conversation: ${response.body}');
    }
  }

  // Message endpoints
  static Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse(
        '$baseUrl/conversations/$conversationId/messages?page=$page&limit=$limit',
      ),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final responseBody = jsonDecode(response.body);
      final data = responseBody['data'];

      if (data != null && data['messages'] != null) {
        final List<dynamic> messages = data['messages'];
        return messages.map((json) => Message.fromJson(json)).toList();
      } else {
        final List<dynamic> messages = responseBody as List<dynamic>;
        return messages.map((json) => Message.fromJson(json)).toList();
      }
    } else {
      throw Exception('Failed to load messages: ${response.body}');
    }
  }

  static Future<Message> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyTo,
  }) async {
    final body = {'content': content, 'type': type};

    // Chỉ thêm replyTo nếu nó không null
    if (replyTo != null) {
      body['replyTo'] = replyTo;
    }

    final response = await http.post(
      Uri.parse('$baseUrl/conversations/$conversationId/messages'),
      headers: await getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  static Future<Message> editMessage(String messageId, String content) async {
    final response = await http.put(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: await getHeaders(),
      body: jsonEncode({'content': content}),
    );

    if (response.statusCode == 200) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to edit message: ${response.body}');
    }
  }

  static Future<void> deleteMessage(String messageId) async {
    final response = await http.delete(
      Uri.parse('$baseUrl/messages/$messageId'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

  static Future<void> markAsRead(String messageId) async {
    final response = await http.post(
      Uri.parse('$baseUrl/messages/$messageId/read'),
      headers: await getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark message as read: ${response.body}');
    }
  }

  // User endpoints
  static Future<User> getCurrentUser() async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/me'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      return User.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to load current user: ${response.body}');
    }
  }

  static Future<List<User>> searchUsers(String query) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/search?q=$query'),
      headers: await getHeaders(),
    );

    if (response.statusCode == 200) {
      final List<dynamic> data = jsonDecode(response.body);
      return data.map((json) => User.fromJson(json)).toList();
    } else {
      throw Exception('Failed to search users: ${response.body}');
    }
  }
}
