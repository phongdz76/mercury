import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/message.dart';
import 'base_service.dart';

class MessageService extends BaseService {
  static Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) async {
    final response = await http.get(
      Uri.parse(
        '${BaseService.baseUrl}/conversations/$conversationId/messages?page=$page&limit=$limit&sort=createdAt&order=asc',
      ),
      headers: await BaseService.getHeaders(),
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

    // Only add replyTo if it's not null
    if (replyTo != null) {
      body['replyTo'] = replyTo;
    }

    final response = await http.post(
      Uri.parse(
        '${BaseService.baseUrl}/conversations/$conversationId/messages',
      ),
      headers: await BaseService.getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message: ${response.body}');
    }
  }

  static Future<Message> sendMessageWithFile({
    required String conversationId,
    required String content,
    required String type,
    required String fileUrl,
    required String fileName,
    required String mimeType,
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
          'mimeType': mimeType,
          'size': fileSize,
        },
      ],
    };

    // Add replyTo if provided
    if (replyTo != null) {
      body['replyTo'] = replyTo;
    }

    final response = await http.post(
      Uri.parse(
        '${BaseService.baseUrl}/conversations/$conversationId/messages',
      ),
      headers: await BaseService.getHeaders(),
      body: jsonEncode(body),
    );

    if (response.statusCode == 201) {
      return Message.fromJson(jsonDecode(response.body));
    } else {
      throw Exception('Failed to send message with file: ${response.body}');
    }
  }

  static Future<Message> editMessage(String messageId, String content) async {
    final response = await http.put(
      Uri.parse('${BaseService.baseUrl}/messages/$messageId'),
      headers: await BaseService.getHeaders(),
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
      Uri.parse('${BaseService.baseUrl}/messages/$messageId'),
      headers: await BaseService.getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to delete message: ${response.body}');
    }
  }

  static Future<void> markAsRead(String messageId) async {
    final response = await http.post(
      Uri.parse('${BaseService.baseUrl}/messages/$messageId/read'),
      headers: await BaseService.getHeaders(),
    );

    if (response.statusCode != 200) {
      throw Exception('Failed to mark message as read: ${response.body}');
    }
  }
}
