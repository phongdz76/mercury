import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/conversation.dart';
import 'base_service.dart';

class ConversationService extends BaseService {
  static Future<List<Conversation>> getConversations() async {
    final response = await http.get(
      Uri.parse('${BaseService.baseUrl}/conversations'),
      headers: await BaseService.getHeaders(),
    );

    final responseBody = jsonDecode(response.body);

    if (response.statusCode == 200) {
      // Handle the nested structure properly
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
      Uri.parse('${BaseService.baseUrl}/conversations/$id'),
      headers: await BaseService.getHeaders(),
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
      Uri.parse('${BaseService.baseUrl}/conversations'),
      headers: await BaseService.getHeaders(),
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
}
