import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import 'package:http_parser/http_parser.dart';
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
      Uri.parse('$baseUrl/me'),
      headers: await getHeaders(),
    );

    final responseBody = jsonDecode(response.body);
    final data = responseBody['data'] ?? responseBody;

    if (response.statusCode == 200) {
      return User.fromJson(data);
    } else {
      throw Exception('Failed to load current user: ${response.body}');
    }
  }

  static String getUserAvatarUrl(String userId) {
    return '$baseUrl/users/$userId/avatar';
  }

  static Future<User> getUserById(String userId) async {
    final response = await http.get(
      Uri.parse('$baseUrl/users/$userId'),
      headers: await getHeaders(),
    );

    final responseBody = jsonDecode(response.body);
    final data = responseBody['data'] ?? responseBody;

    if (response.statusCode == 200) {
      return User.fromJson(data['user'] ?? data);
    } else {
      throw Exception('Failed to load user: ${response.body}');
    }
  }

  // Profile endpoints
  static Future<User> getProfile() async {
    final response = await http.get(
      Uri.parse('$baseUrl${ApiConstants.profile}'),
      headers: await getHeaders(),
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
      Uri.parse('$baseUrl${ApiConstants.profile}'),
      headers: await getHeaders(),
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
      Uri.parse('$baseUrl${ApiConstants.changePassword}'),
      headers: await getHeaders(),
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

  // Upload avatar endpoint
  static Future<String> uploadAvatar(File imageFile) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/avatar'),
      );

      // Add headers
      final headers = await getHeaders();
      request.headers.addAll(headers);

      // Add file to request
      final fileStream = http.ByteStream(imageFile.openRead());
      final fileLength = await imageFile.length();

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: imageFile.path.split('/').last,
        contentType: MediaType('image', 'jpeg'), // Adjust based on file type
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        // Return the avatar URL from response
        return jsonResponse['data']['user']['avatar'] ??
            jsonResponse['avatarUrl'];
      } else {
        throw Exception(
          'Failed to upload avatar: ${jsonResponse['message'] ?? responseBody}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload avatar: $e');
    }
  }

  // Upload file for messages
  // Hàm helper để xác định mimetype
  static String getMimeType(String filePath) {
    final extension = filePath.split('.').last.toLowerCase();

    final mimeTypeMap = {
      'jpg': 'image/jpeg',
      'jpeg': 'image/jpeg',
      'png': 'image/png',
      'gif': 'image/gif',
      'webp': 'image/webp',
      'bmp': 'image/bmp',
      'tiff': 'image/tiff',
      'svg': 'image/svg+xml',
      'pdf': 'application/pdf',
      'doc': 'application/msword',
      'docx':
          'application/vnd.openxmlformats-officedocument.wordprocessingml.document',
      'txt': 'text/plain',
      'mp4': 'video/mp4',
      'mp3': 'audio/mpeg',
      'wav': 'audio/wav',
      'zip': 'application/zip',
      'rar': 'application/x-rar-compressed',
    };

    return mimeTypeMap[extension] ?? 'application/octet-stream';
  }

  static Future<Map<String, dynamic>> uploadMessageFile(
    File file,
    String conversationId,
  ) async {
    try {
      final request = http.MultipartRequest(
        'POST',
        Uri.parse('$baseUrl/upload/attachment'),
      );

      // Add headers
      final headers = await getHeaders();
      request.headers.addAll(headers);

      // Add file to request
      final fileStream = http.ByteStream(file.openRead());
      final fileLength = await file.length();

      // Determine content type based on file extension
      final mimetype = getMimeType(file.path);

      final multipartFile = http.MultipartFile(
        'file',
        fileStream,
        fileLength,
        filename: file.path.split('/').last,
        contentType: MediaType.parse(mimetype),
      );

      request.files.add(multipartFile);

      final response = await request.send();
      final responseBody = await response.stream.bytesToString();
      final jsonResponse = jsonDecode(responseBody);

      if (response.statusCode == 200) {
        // Return comprehensive file info including mimetype
        return {
          'url': jsonResponse['data']['file']['url'] ?? jsonResponse['fileUrl'],
          'name':
              jsonResponse['data']['file']['name'] ?? file.path.split('/').last,
          'size': jsonResponse['data']['file']['size'] ?? fileLength,
          'type': jsonResponse['data']['file']['type'] ?? 'FILE',
          'mimetype': mimetype, // Thêm mimetype vào response
        };
      } else {
        throw Exception(
          'Failed to upload file: ${jsonResponse['message'] ?? responseBody}',
        );
      }
    } catch (e) {
      throw Exception('Failed to upload file: $e');
    }
  }

  // Send message with file attachment
  static Future<Message> sendMessageWithFile({
    required String conversationId,
    required String content,
    required String type,
    required String fileUrl,
    required String fileName,
    required String mimeType, // Thêm parameter mimetype
    required int fileSize,
    String? replyTo,
  }) async {
    final body = {
      'content': content,
      'type': type,
      'attachments': [
        {
          'name': fileName,
          'url': fileUrl,
          'type': type,
          'mimeType': mimeType, // Thêm mimetype vào attachment
          'size': fileSize,
        },
      ],
    };

    // Add replyTo if provided
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
      throw Exception('Failed to send message with file: ${response.body}');
    }
  }
}
