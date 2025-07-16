import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/websocket_event.dart';
import '../services/api_service.dart';
import '../services/websocket_service.dart';

class ChatProvider extends ChangeNotifier {
  final WebSocketService _webSocketService = WebSocketService();

  User? _currentUser;
  List<Conversation> _conversations = [];
  Map<String, List<Message>> _messages = {};
  Map<String, bool> _typingUsers = {};
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  List<Conversation> get conversations => _conversations;
  Map<String, List<Message>> get messages => _messages;
  Map<String, bool> get typingUsers => _typingUsers;
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _webSocketService.isConnected;

  ChatProvider() {
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _webSocketService.events.listen((event) {
      _handleWebSocketEvent(event);
    });
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case 'message':
        _handleNewMessage(event);
        break;
      case 'typing':
        _handleTyping(event);
        break;
      case 'read':
        _handleMessageRead(event);
        break;
      case 'user_joined':
      case 'user_left':
        _handleUserPresence(event);
        break;
    }
  }

  void _handleNewMessage(WebSocketEvent event) {
    try {
      final message = Message.fromJson(event.data);
      final conversationId = event.conversationId;

      if (conversationId != null) {
        if (!_messages.containsKey(conversationId)) {
          _messages[conversationId] = [];
        }
        _messages[conversationId]!.add(message);
        _messages[conversationId]!.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
        notifyListeners();
      }
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  void _handleTyping(WebSocketEvent event) {
    final conversationId = event.conversationId;
    final isTyping = event.data['isTyping'] ?? false;

    if (conversationId != null) {
      _typingUsers[conversationId] = isTyping;
      notifyListeners();
    }
  }

  void _handleMessageRead(WebSocketEvent event) {
    // Update read receipts
    notifyListeners();
  }

  void _handleUserPresence(WebSocketEvent event) {
    // Handle user join/leave events
    notifyListeners();
  }

  Future<void> initialize() async {
    await _loadCurrentUser();
    await _connectWebSocket();
    await _loadConversations();
  }

  Future<void> _loadCurrentUser() async {
    try {
      _currentUser = await ApiService.getCurrentUser();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load user: $e';
      notifyListeners();
    }
  }

  Future<void> _connectWebSocket() async {
    try {
      await _webSocketService.connect();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to connect to WebSocket: $e';
      notifyListeners();
    }
  }

  Future<void> _loadConversations() async {
    _setLoading(true);
    try {
      _conversations = await ApiService.getConversations();
      _error = null;
    } catch (e) {
      _error = 'Failed to load conversations: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      final messages = await ApiService.getMessages(conversationId);
      _messages[conversationId] = messages;
      _webSocketService.joinConversation(conversationId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load messages: $e';
      notifyListeners();
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? replyTo,
  }) async {
    try {
      // Send via WebSocket for real-time
      _webSocketService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        replyTo: replyTo,
      );

      // Also send via REST API as backup
      await ApiService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        replyTo: replyTo,
      );
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  Future<void> createConversation({
    required String type,
    required List<String> participants,
    String? title,
  }) async {
    try {
      final conversation = await ApiService.createConversation(
        type: type,
        participants: participants,
        title: title,
      );
      _conversations.insert(0, conversation);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to create conversation: $e';
      notifyListeners();
    }
  }

  void sendTyping(String conversationId, bool isTyping) {
    _webSocketService.sendTyping(conversationId, isTyping);
  }

  void markAsRead(String conversationId, String messageId) {
    _webSocketService.markAsRead(conversationId, messageId);
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void updateCurrentUser(User updatedUser) {
    _currentUser = updatedUser;
    notifyListeners();
  }

  Future<void> refreshProfile() async {
    try {
      _currentUser = await ApiService.getProfile();
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh profile: $e';
      notifyListeners();
    }
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
