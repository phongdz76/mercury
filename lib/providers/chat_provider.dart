import 'dart:io';
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
  Map<String, User> _userCache = {}; // Add user cache
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  List<Conversation> get conversations => _conversations;
  Map<String, List<Message>> get messages => _messages;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, User> get userCache => _userCache; // Add getter for user cache
  bool get isLoading => _isLoading;
  String? get error => _error;
  bool get isConnected => _webSocketService.isConnected;

  ChatProvider() {
    _initializeWebSocket();
  }

  void _initializeWebSocket() {
    _webSocketService.events.listen(
      (event) {
        _handleWebSocketEvent(event);
      },
      onError: (error) {
        print('WebSocket error in ChatProvider: $error');
        _error = 'Connection error: $error';
        notifyListeners();
      },
    );
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
      case 'conversation_created':
        _handleConversationCreated(event);
        break;
      case 'conversation_updated':
        _handleConversationUpdated(event);
        break;
      case 'conversation_deleted':
        _handleConversationDeleted(event);
        break;
      case 'participant_added':
        _handleParticipantAdded(event);
        break;
      case 'participant_removed':
        _handleParticipantRemoved(event);
        break;
      case 'conversation_status_changed':
        _handleConversationStatusChanged(event);
        break;
    }
  }

  void _handleNewMessage(WebSocketEvent event) {
    try {
      final message = Message.fromJson(event.data);
      final conversationId = event.conversationId;

      if (conversationId != null) {
        // Add message to messages list
        if (!_messages.containsKey(conversationId)) {
          _messages[conversationId] = [];
        }
        _messages[conversationId]!.add(message);
        _messages[conversationId]!.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );

        // Update the conversation's last message and last activity
        final conversationIndex = _conversations.indexWhere((c) => c.id == conversationId);
        if (conversationIndex != -1) {
          final conversation = _conversations[conversationIndex];
          
          // Format last message based on message type
          String lastMessage = message.content;
          if (message.type == 'image') {
            lastMessage = '📷 Image';
          } else if (message.type == 'file') {
            lastMessage = '📁 File';
          } else if (message.type == 'audio') {
            lastMessage = '🎵 Audio';
          } else if (message.type == 'video') {
            lastMessage = '🎥 Video';
          } else if (message.type == 'location') {
            lastMessage = '📍 Location';
          }
          
          final updatedConversation = Conversation(
            id: conversation.id,
            type: conversation.type,
            participants: conversation.participants,
            title: conversation.title,
            description: conversation.description,
            createdBy: conversation.createdBy,
            lastMessage: lastMessage,
            lastActivity: message.createdAt,
            isActive: conversation.isActive,
            createdAt: conversation.createdAt,
            updatedAt: DateTime.now(),
          );
          
          _conversations[conversationIndex] = updatedConversation;
          
          // Sort conversations by last activity
          _sortConversations();
        }
        
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
    try {
      final conversationId = event.conversationId;
      final messageId = event.data['messageId'] as String?;
      
      if (conversationId != null && messageId != null) {
        // Update read status for the specific message
        final messages = _messages[conversationId];
        if (messages != null) {
          final messageIndex = messages.indexWhere((m) => m.id == messageId);
          if (messageIndex != -1) {
            // Here you could update the message's read status
            // This would require extending the Message model to include read receipts
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error handling message read: $e');
    }
  }

  void _handleUserPresence(WebSocketEvent event) {
    // Handle user join/leave events
    notifyListeners();
  }

  void _handleConversationCreated(WebSocketEvent event) {
    try {
      final conversation = Conversation.fromJson(event.data['conversation']);
      
      // Add to conversations list if not already present
      if (!_conversations.any((c) => c.id == conversation.id)) {
        _conversations.add(conversation);
        _sortConversations();
        notifyListeners();
      }
    } catch (e) {
      print('Error handling conversation created: $e');
    }
  }

  void _handleConversationUpdated(WebSocketEvent event) {
    try {
      final updatedConversation = Conversation.fromJson(event.data['conversation']);
      
      // Find and update the conversation in the list
      final index = _conversations.indexWhere((c) => c.id == updatedConversation.id);
      if (index != -1) {
        _conversations[index] = updatedConversation;
        notifyListeners();
      }
    } catch (e) {
      print('Error handling conversation updated: $e');
    }
  }

  void _handleConversationDeleted(WebSocketEvent event) {
    try {
      final conversationId = event.data['conversationId'] as String?;
      
      if (conversationId != null) {
        // Remove from conversations list
        _conversations.removeWhere((c) => c.id == conversationId);
        
        // Remove messages for this conversation
        _messages.remove(conversationId);
        
        // Remove typing indicator
        _typingUsers.remove(conversationId);
        
        notifyListeners();
      }
    } catch (e) {
      print('Error handling conversation deleted: $e');
    }
  }

  void _handleParticipantAdded(WebSocketEvent event) {
    try {
      final conversationId = event.conversationId;
      final participantId = event.data['participantId'] as String?;
      
      if (conversationId != null && participantId != null) {
        // Find the conversation and update participants
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final conversation = _conversations[index];
          final updatedParticipants = List<String>.from(conversation.participants);
          
          if (!updatedParticipants.contains(participantId)) {
            updatedParticipants.add(participantId);
            
            // Create updated conversation
            final updatedConversation = Conversation(
              id: conversation.id,
              type: conversation.type,
              participants: updatedParticipants,
              title: conversation.title,
              description: conversation.description,
              createdBy: conversation.createdBy,
              lastMessage: conversation.lastMessage,
              lastActivity: conversation.lastActivity,
              isActive: conversation.isActive,
              createdAt: conversation.createdAt,
              updatedAt: DateTime.now(),
            );
            
            _conversations[index] = updatedConversation;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error handling participant added: $e');
    }
  }

  void _handleParticipantRemoved(WebSocketEvent event) {
    try {
      final conversationId = event.conversationId;
      final participantId = event.data['participantId'] as String?;
      
      if (conversationId != null && participantId != null) {
        // Find the conversation and update participants
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final conversation = _conversations[index];
          final updatedParticipants = List<String>.from(conversation.participants);
          
          if (updatedParticipants.contains(participantId)) {
            updatedParticipants.remove(participantId);
            
            // Create updated conversation
            final updatedConversation = Conversation(
              id: conversation.id,
              type: conversation.type,
              participants: updatedParticipants,
              title: conversation.title,
              description: conversation.description,
              createdBy: conversation.createdBy,
              lastMessage: conversation.lastMessage,
              lastActivity: conversation.lastActivity,
              isActive: conversation.isActive,
              createdAt: conversation.createdAt,
              updatedAt: DateTime.now(),
            );
            
            _conversations[index] = updatedConversation;
            notifyListeners();
          }
        }
      }
    } catch (e) {
      print('Error handling participant removed: $e');
    }
  }

  void _handleConversationStatusChanged(WebSocketEvent event) {
    try {
      final conversationId = event.conversationId;
      final isActive = event.data['isActive'] as bool? ?? true;
      
      if (conversationId != null) {
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final conversation = _conversations[index];
          final updatedConversation = Conversation(
            id: conversation.id,
            type: conversation.type,
            participants: conversation.participants,
            title: conversation.title,
            description: conversation.description,
            createdBy: conversation.createdBy,
            lastMessage: conversation.lastMessage,
            lastActivity: conversation.lastActivity,
            isActive: isActive,
            createdAt: conversation.createdAt,
            updatedAt: DateTime.now(),
          );
          
          _conversations[index] = updatedConversation;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error handling conversation status changed: $e');
    }
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
      _sortConversations();
      _error = null;
    } catch (e) {
      _error = 'Failed to load conversations: $e';
    } finally {
      _setLoading(false);
    }
  }

  Future<void> refreshConversations() async {
    try {
      _conversations = await ApiService.getConversations();
      _sortConversations();
      _error = null;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to refresh conversations: $e';
      notifyListeners();
    }
  }

  void _sortConversations() {
    _conversations.sort((a, b) => b.lastActivity.compareTo(a.lastActivity));
  }

  void addConversationToList(Conversation conversation) {
    if (!_conversations.any((c) => c.id == conversation.id)) {
      _conversations.add(conversation);
      _sortConversations();
      notifyListeners();
    }
  }

  void removeConversationFromList(String conversationId) {
    _conversations.removeWhere((c) => c.id == conversationId);
    _messages.remove(conversationId);
    _typingUsers.remove(conversationId);
    notifyListeners();
  }

  void updateConversationInList(Conversation conversation) {
    final index = _conversations.indexWhere((c) => c.id == conversation.id);
    if (index != -1) {
      _conversations[index] = conversation;
      _sortConversations();
      notifyListeners();
    }
  }

  bool hasConversation(String conversationId) {
    return _conversations.any((c) => c.id == conversationId);
  }

  Conversation? getConversationById(String conversationId) {
    try {
      return _conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
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
        // include myself as a participant
        participants: [
          if (_currentUser != null) _currentUser!.id,
          ...participants,
        ],
        title: title,
      );
      _conversations.add(conversation);
      _sortConversations();
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

  // Upload file and send message
  Future<void> sendMessageWithFile({
    required String conversationId,
    required File file,
    required String type,
    String? caption,
    String? replyTo,
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload file first
      final uploadResponse = await ApiService.uploadMessageFile(
        file,
        conversationId,
      );
      final fileUrl = uploadResponse['url'] as String;

      // Get file info
      final fileName = file.path.split('/').last;
      final fileSize = await file.length();

      // Send message with file attachment
      final message = await ApiService.sendMessageWithFile(
        conversationId: conversationId,
        content: caption ?? fileName,
        type: type,
        fileUrl: fileUrl,
        mimeType: file.path.split('.').last,
        fileName: fileName,
        fileSize: fileSize,
        replyTo: replyTo,
      );

      // Add to local messages
      if (!_messages.containsKey(conversationId)) {
        _messages[conversationId] = [];
      }
      _messages[conversationId]!.add(message);
      _messages[conversationId]!.sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );

      // Also send via WebSocket for real-time
      _webSocketService.sendMessage(
        conversationId: conversationId,
        content: caption ?? fileName,
        type: type,
        replyTo: replyTo,
      );

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to send file: $e';
      notifyListeners();
    }
  }

  // Update current user (for profile updates)
  void updateCurrentUser(User user) {
    _currentUser = user;
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

  void _setLoading(bool loading) {
    _isLoading = loading;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  Future<User?> getUser(String userId) async {
    // Check cache first
    if (_userCache.containsKey(userId)) {
      return _userCache[userId];
    }

    try {
      final user = await ApiService.getUserById(userId);
      _userCache[userId] = user;
      return user;
    } catch (e) {
      print('Error fetching user $userId: $e');
      return null;
    }
  }

  String getOtherParticipant(Conversation conversation) {
    return conversation.participants.firstWhere(
      (id) => id != _currentUser?.id,
      orElse: () => conversation.participants.first,
    );
  }

  @override
  void dispose() {
    _webSocketService.dispose();
    super.dispose();
  }
}
