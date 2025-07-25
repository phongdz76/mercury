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
        // Skip messages from current user to avoid duplicates
        // (current user's messages are handled via optimistic updates)
        if (message.sender == _currentUser?.id) {
          return;
        }

        // Add message to messages list
        if (!_messages.containsKey(conversationId)) {
          _messages[conversationId] = [];
        }

        // Check if message already exists to prevent duplicates
        final existingMessageIndex = _messages[conversationId]!.indexWhere(
          (m) => m.id == message.id,
        );

        if (existingMessageIndex == -1) {
          // Message doesn't exist, add it
          _messages[conversationId]!.add(message);
          _messages[conversationId]!.sort(
            (a, b) => a.createdAt.compareTo(b.createdAt),
          );
        } else {
          // Message exists, update it (in case of edits)
          _messages[conversationId]![existingMessageIndex] = message;
        }

        // Update the conversation's last message and last activity
        final conversationIndex = _conversations.indexWhere(
          (c) => c.id == conversationId,
        );
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
      final updatedConversation = Conversation.fromJson(
        event.data['conversation'],
      );

      // Find and update the conversation in the list
      final index = _conversations.indexWhere(
        (c) => c.id == updatedConversation.id,
      );
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
          final updatedParticipants = List<String>.from(
            conversation.participants,
          );

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
          final updatedParticipants = List<String>.from(
            conversation.participants,
          );

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
      // Prevent loading if already in progress
      if (_isLoading) {
        return;
      }

      _setLoading(true);
      final messages = await ApiService.getMessages(conversationId);

      // Sort messages by creation time to ensure proper order
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messages[conversationId] = messages;

      _webSocketService.joinConversation(conversationId);
      notifyListeners();
    } catch (e) {
      _error = 'Failed to load messages: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Method to force reload messages (useful for refreshing chat)
  Future<void> reloadMessages(String conversationId) async {
    try {
      _setLoading(true);
      final messages = await ApiService.getMessages(conversationId);

      // Sort messages by creation time to ensure proper order
      messages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messages[conversationId] = messages;
      notifyListeners();
    } catch (e) {
      _error = 'Failed to reload messages: $e';
      notifyListeners();
    } finally {
      _setLoading(false);
    }
  }

  // Method to clear messages for a conversation (call when leaving chat)
  void clearConversationMessages(String conversationId) {
    _messages.remove(conversationId);
    _typingUsers.remove(conversationId);
    notifyListeners();
  }

  // Method to leave a conversation room
  void leaveConversation(String conversationId) {
    _webSocketService.leaveConversation(conversationId);
    clearConversationMessages(conversationId);
  }

  // Method to reset all chat state (useful when logging out or reinitializing)
  void resetChatState() {
    _conversations.clear();
    _messages.clear();
    _typingUsers.clear();
    _userCache.clear();
    _currentUser = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? replyTo,
  }) async {
    try {
      // Create optimistic message for immediate UI update
      final tempId = 'temp_${DateTime.now().millisecondsSinceEpoch}';
      final optimisticMessage = Message(
        id: tempId,
        conversationId: conversationId,
        sender: _currentUser?.id ?? '',
        content: content,
        type: type,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
        replyTo: replyTo,
        readBy: [],
        attachments: [],
        isEdited: false,
        isDeleted: false,
        editedAt: null,
        deletedAt: null,
      );

      // Add optimistic message to local messages immediately
      if (!_messages.containsKey(conversationId)) {
        _messages[conversationId] = [];
      }
      _messages[conversationId]!.add(optimisticMessage);
      _messages[conversationId]!.sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );
      notifyListeners();

      // Send via REST API (primary method)
      final sentMessage = await ApiService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        replyTo: replyTo,
      );

      // Replace optimistic message with real message
      final messageIndex = _messages[conversationId]!.indexWhere(
        (m) => m.id == tempId,
      );
      
      if (messageIndex != -1) {
        _messages[conversationId]![messageIndex] = sentMessage;
      } else {
        // Fallback: add message if optimistic message not found
        _messages[conversationId]!.add(sentMessage);
        _messages[conversationId]!.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
      }

      notifyListeners();
    } catch (e) {
      // Remove optimistic message on error  
      _messages[conversationId]?.removeWhere((m) => m.id.startsWith('temp_'));
      
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

      // Check if message already exists to prevent duplicates
      final existingMessageIndex = _messages[conversationId]!.indexWhere(
        (m) => m.id == message.id,
      );

      if (existingMessageIndex == -1) {
        // Message doesn't exist, add it
        _messages[conversationId]!.add(message);
        _messages[conversationId]!.sort(
          (a, b) => a.createdAt.compareTo(b.createdAt),
        );
      }

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

  Future<Conversation> createOrGetConversation({
    required String type,
    required List<String> participants,
    String? title,
  }) async {
    try {
      // Check if a conversation already exists with these participants
      final existingConversation = _findExistingConversation(
        participants,
        type,
      );

      if (existingConversation != null) {
        return existingConversation;
      }

      // Create new conversation
      final conversation = await ApiService.createConversation(
        type: type,
        participants: participants,
        title: title,
      );

      // Add to local list
      _conversations.add(conversation);
      _sortConversations();
      notifyListeners();

      return conversation;
    } catch (e) {
      throw Exception('Failed to create or get conversation: $e');
    }
  }

  Conversation? _findExistingConversation(
    List<String> participants,
    String type,
  ) {
    for (final conversation in _conversations) {
      if (conversation.type == type) {
        // For direct conversations, check if participants match (including current user)
        if (type == 'direct' && conversation.participants.length == 2) {
          final allParticipants = [
            ...participants,
            _currentUser?.id,
          ].where((id) => id != null).toList();
          final conversationParticipants = conversation.participants.toSet();
          final targetParticipants = allParticipants.toSet();

          if (conversationParticipants.length == targetParticipants.length &&
              conversationParticipants.containsAll(targetParticipants)) {
            return conversation;
          }
        }
        // For group conversations, check if exact same participants
        else if (type == 'group') {
          final allParticipants = [
            ...participants,
            _currentUser?.id,
          ].where((id) => id != null).toList();
          final conversationParticipants = conversation.participants.toSet();
          final targetParticipants = allParticipants.toSet();

          if (conversationParticipants.length == targetParticipants.length &&
              conversationParticipants.containsAll(targetParticipants)) {
            return conversation;
          }
        }
      }
    }
    return null;
  }

  // Message read status methods
  bool shouldShowReadIndicator(String messageId, String conversationId) {
    final messages = _messages[conversationId] ?? [];
    final message = messages.where((m) => m.id == messageId).firstOrNull;

    if (message == null) return false;

    // Only show read indicator for messages sent by current user
    return message.sender == _currentUser?.id;
  }

  List<ReadReceipt> getMessageReadReceipts(
    String messageId,
    String conversationId,
  ) {
    final messages = _messages[conversationId] ?? [];
    final message = messages.where((m) => m.id == messageId).firstOrNull;

    if (message == null) return [];

    return message.readBy ?? [];
  }

  String getReadStatusText(String messageId, String conversationId) {
    final readReceipts = getMessageReadReceipts(messageId, conversationId);

    if (readReceipts.isEmpty) {
      return 'Sent';
    } else if (readReceipts.length == 1) {
      return 'Read';
    } else {
      return 'Read by ${readReceipts.length}';
    }
  }

  bool isMessageReadByCurrentUser(String messageId, String conversationId) {
    final messages = _messages[conversationId] ?? [];
    final message = messages.where((m) => m.id == messageId).firstOrNull;

    if (message == null) return true;

    // If current user sent the message, consider it as "read"
    if (message.sender == _currentUser?.id) return true;

    // Check if current user has read receipt for this message
    final readReceipts = message.readBy ?? [];
    return readReceipts.any((receipt) => receipt.userId == _currentUser?.id);
  }

  Map<String, dynamic> getConversationReadStatus(String conversationId) {
    final messages = _messages[conversationId] ?? [];
    final currentUserId = _currentUser?.id;

    if (currentUserId == null) {
      return {'unreadCount': 0, 'lastReadMessageId': null};
    }

    int unreadCount = 0;
    String? lastReadMessageId;

    for (final message in messages.reversed) {
      if (message.sender == currentUserId) {
        // Skip own messages
        continue;
      }

      final isRead = isMessageReadByCurrentUser(message.id, conversationId);
      if (isRead) {
        if (lastReadMessageId == null) {
          lastReadMessageId = message.id;
        }
      } else {
        unreadCount++;
      }
    }

    return {'unreadCount': unreadCount, 'lastReadMessageId': lastReadMessageId};
  }

  int getUnreadMessagesCount(String conversationId) {
    final status = getConversationReadStatus(conversationId);
    return status['unreadCount'] as int;
  }

  Future<void> markAllMessagesAsRead(String conversationId) async {
    final messages = _messages[conversationId] ?? [];
    final currentUserId = _currentUser?.id;

    if (currentUserId == null) return;

    try {
      // Find all unread messages not sent by current user
      final unreadMessages = messages
          .where(
            (message) =>
                message.sender != currentUserId &&
                !isMessageReadByCurrentUser(message.id, conversationId),
          )
          .toList();

      for (final message in unreadMessages) {
        // Mark as read via WebSocket
        markAsRead(conversationId, message.id);

        // Update local state
        _markMessageAsReadLocally(message.id, conversationId, currentUserId);
      }

      notifyListeners();
    } catch (e) {
      print('Error marking all messages as read: $e');
    }
  }

  Future<void> markMessagesAsReadWhenVisible(
    String conversationId,
    List<String> visibleMessageIds,
  ) async {
    final currentUserId = _currentUser?.id;
    if (currentUserId == null) return;

    try {
      for (final messageId in visibleMessageIds) {
        if (!isMessageReadByCurrentUser(messageId, conversationId)) {
          // Mark as read via WebSocket
          markAsRead(conversationId, messageId);

          // Update local state
          _markMessageAsReadLocally(messageId, conversationId, currentUserId);
        }
      }

      notifyListeners();
    } catch (e) {
      print('Error marking visible messages as read: $e');
    }
  }

  void _markMessageAsReadLocally(
    String messageId,
    String conversationId,
    String userId,
  ) {
    final messages = _messages[conversationId] ?? [];
    final messageIndex = messages.indexWhere((m) => m.id == messageId);

    if (messageIndex != -1) {
      final message = messages[messageIndex];
      final readReceipts = message.readBy ?? <ReadReceipt>[];

      // Check if user hasn't already read this message
      if (!readReceipts.any((receipt) => receipt.userId == userId)) {
        readReceipts.add(ReadReceipt(userId: userId, readAt: DateTime.now()));

        // Create updated message with new read receipt
        final updatedMessage = Message(
          id: message.id,
          conversationId: message.conversationId,
          sender: message.sender,
          content: message.content,
          type: message.type,
          createdAt: message.createdAt,
          updatedAt: message.updatedAt,
          replyTo: message.replyTo,
          readBy: readReceipts,
          attachments: message.attachments,
          isEdited: message.isEdited,
          isDeleted: message.isDeleted,
          editedAt: message.editedAt,
          deletedAt: message.deletedAt,
        );

        messages[messageIndex] = updatedMessage;
      }
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
