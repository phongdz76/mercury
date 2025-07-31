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
  Map<String, List<Map<String, dynamic>>> _pendingAttachments =
      {}; // Hold pending attachments
  Map<String, Message?> _replyingToMessages =
      {}; // Track reply state per conversation
  bool _isLoading = false;
  String? _error;

  // Getters
  User? get currentUser => _currentUser;
  List<Conversation> get conversations => _conversations;
  Map<String, List<Message>> get messages => _messages;
  Map<String, bool> get typingUsers => _typingUsers;
  Map<String, User> get userCache => _userCache; // Add getter for user cache
  Map<String, List<Map<String, dynamic>>> get pendingAttachments =>
      _pendingAttachments; // Getter for pending attachments
  Map<String, Message?> get replyingToMessages =>
      _replyingToMessages; // Getter for reply state
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
      case 'conversation_list_updated':
        _handleConversationListUpdated(event);
        break;
      case 'conversation_read_status_changed':
        _handleConversationReadStatusChanged(event);
        break;
      case 'conversation_muted':
        _handleConversationMuted(event);
        break;
      case 'conversation_archived':
        _handleConversationArchived(event);
        break;
      case 'unread_count_updated':
        _handleUnreadCountUpdated(event);
        break;
    }
  }

  void _handleNewMessage(WebSocketEvent event) {
    try {
      final message = Message.fromJson(event.data);
      final conversationId = event.conversationId;

      if (conversationId != null) {
        // Validate message before processing
        if (!_isValidMessage(message)) {
          print(
            'Invalid message received, skipping: ${message.id}, content: "${message.content}", sender: ${message.sender}, type: ${message.type}',
          );
          return;
        }

        print(
          'Processing valid message: ${message.id}, content: "${message.content}", sender: ${message.sender}',
        );

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

        // Preload sender information if not already cached
        if (!_userCache.containsKey(message.sender)) {
          getUser(message.sender);
        }

        // Update the conversation's last message and last activity
        _updateConversationLastMessage(conversationId, message);

        notifyListeners();
      }
    } catch (e) {
      print('Error handling new message: $e');
    }
  }

  // Helper method to validate if a message is valid
  bool _isValidMessage(Message message) {
    // Check if message has valid ID
    if (message.id.isEmpty) {
      return false;
    }

    // Check if message has valid sender
    if (message.sender.isEmpty) {
      return false;
    }

    // Check if message content is not empty for text messages
    if (message.type == 'text' && message.content.trim().isEmpty) {
      return false;
    }

    // Check if message is not deleted
    if (message.isDeleted) {
      return false;
    }

    return true;
  }

  // Debug method to check messages in a conversation
  void debugConversationMessages(String conversationId) {
    final messages = _messages[conversationId] ?? [];
    print('=== Debug Messages for Conversation $conversationId ===');
    print('Total messages: ${messages.length}');

    for (int i = 0; i < messages.length; i++) {
      final msg = messages[i];
      print(
        '[$i] ID: ${msg.id}, Sender: ${msg.sender}, Content: "${msg.content}", Type: ${msg.type}, Time: ${msg.createdAt}',
      );
    }
    print('=== End Debug Messages ===');
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

        // Remove pending attachments
        _pendingAttachments.remove(conversationId);

        // Remove reply state
        _replyingToMessages.remove(conversationId);

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

  // New handler methods for enhanced real-time features
  void _handleConversationListUpdated(WebSocketEvent event) {
    try {
      final conversationData = event.data['conversation'];
      if (conversationData != null) {
        final conversation = Conversation.fromJson(conversationData);
        updateConversationInList(conversation);
      }
    } catch (e) {
      print('Error handling conversation list updated: $e');
    }
  }

  void _handleConversationReadStatusChanged(WebSocketEvent event) {
    try {
      final conversationId = event.conversationId;
      final unreadCount = event.data['unreadCount'] as int? ?? 0;

      if (conversationId != null) {
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final conversation = _conversations[index];
          final updatedConversation = conversation.copyWith(
            unreadCount: unreadCount,
            updatedAt: DateTime.now(),
          );

          _conversations[index] = updatedConversation;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error handling conversation read status changed: $e');
    }
  }

  void _handleConversationMuted(WebSocketEvent event) {
    try {
      final conversationId = event.conversationId;
      final isMuted = event.data['isMuted'] as bool? ?? false;

      if (conversationId != null) {
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final conversation = _conversations[index];
          final updatedConversation = conversation.copyWith(
            isMuted: isMuted,
            updatedAt: DateTime.now(),
          );

          _conversations[index] = updatedConversation;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error handling conversation muted: $e');
    }
  }

  void _handleConversationArchived(WebSocketEvent event) {
    try {
      final conversationId = event.conversationId;
      final isArchived = event.data['isArchived'] as bool? ?? false;

      if (conversationId != null) {
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final conversation = _conversations[index];
          final updatedConversation = conversation.copyWith(
            isArchived: isArchived,
            updatedAt: DateTime.now(),
          );

          _conversations[index] = updatedConversation;

          // If archived, remove from main list or move to archived section
          if (isArchived) {
            // You can implement archived conversations logic here
          }

          _sortConversations();
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error handling conversation archived: $e');
    }
  }

  void _handleUnreadCountUpdated(WebSocketEvent event) {
    try {
      final conversationId = event.conversationId;
      final unreadCount = event.data['unreadCount'] as int? ?? 0;

      if (conversationId != null) {
        final index = _conversations.indexWhere((c) => c.id == conversationId);
        if (index != -1) {
          final conversation = _conversations[index];
          final updatedConversation = conversation.copyWith(
            unreadCount: unreadCount,
          );

          _conversations[index] = updatedConversation;
          notifyListeners();
        }
      }
    } catch (e) {
      print('Error handling unread count updated: $e');
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
      // Auto-subscribe to conversation list updates after connection
      _webSocketService.subscribeToConversationList();
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
    _conversations.sort((a, b) {
      // First, prioritize conversations with unread messages
      if (a.unreadCount > 0 && b.unreadCount == 0) return -1;
      if (a.unreadCount == 0 && b.unreadCount > 0) return 1;

      // Then sort by last activity
      return b.lastActivity.compareTo(a.lastActivity);
    });
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
    _pendingAttachments.remove(
      conversationId,
    ); // Also clear pending attachments
    _replyingToMessages.remove(conversationId); // Clear reply state
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

  // Enhanced conversation management methods
  void markConversationAsRead(String conversationId) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      if (conversation.unreadCount > 0) {
        final updatedConversation = conversation.copyWith(unreadCount: 0);
        _conversations[index] = updatedConversation;
        notifyListeners();

        // Notify server via WebSocket
        _webSocketService.markConversationAsRead(conversationId);
      }
    }
  }

  void muteConversation(String conversationId, bool mute) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      final updatedConversation = conversation.copyWith(isMuted: mute);
      _conversations[index] = updatedConversation;
      notifyListeners();

      // Notify server via WebSocket
      _webSocketService.muteConversation(conversationId, mute);
    }
  }

  void archiveConversation(String conversationId, bool archive) {
    final index = _conversations.indexWhere((c) => c.id == conversationId);
    if (index != -1) {
      final conversation = _conversations[index];
      final updatedConversation = conversation.copyWith(isArchived: archive);
      _conversations[index] = updatedConversation;
      _sortConversations();
      notifyListeners();

      // Notify server via WebSocket
      _webSocketService.archiveConversation(conversationId, archive);
    }
  }

  int getTotalUnreadCount() {
    return _conversations
        .where((c) => !c.isArchived && !c.isMuted)
        .fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }

  List<Conversation> getActiveConversations() {
    return _conversations.where((c) => !c.isArchived && c.isActive).toList();
  }

  List<Conversation> getArchivedConversations() {
    return _conversations.where((c) => c.isArchived).toList();
  }

  List<Conversation> getMutedConversations() {
    return _conversations.where((c) => c.isMuted).toList();
  }

  List<Conversation> getUnreadConversations() {
    return _conversations.where((c) => c.unreadCount > 0).toList();
  }

  // Subscribe to conversation list updates when screen is active
  void subscribeToConversationListUpdates() {
    _webSocketService.subscribeToConversationList();
  }

  // Unsubscribe when screen is inactive
  void unsubscribeFromConversationListUpdates() {
    _webSocketService.unsubscribeFromConversationList();
  }

  // Request fresh conversation list from server
  void requestConversationListRefresh() {
    _webSocketService.refreshConversationList();
  }

  Future<void> loadMessages(String conversationId) async {
    try {
      // Prevent loading if already in progress
      if (_isLoading) {
        return;
      }

      _setLoading(true);
      final messages = await ApiService.getMessages(conversationId);

      // Filter out invalid messages before processing
      final validMessages = messages
          .where((message) => _isValidMessage(message))
          .toList();

      // Sort messages by creation time to ensure proper order
      validMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messages[conversationId] = validMessages;

      // Preload user information for conversation participants and message senders
      await preloadConversationUsers(conversationId);
      await preloadMessageSenders(conversationId);

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

      // Filter out invalid messages before processing
      final validMessages = messages
          .where((message) => _isValidMessage(message))
          .toList();

      // Sort messages by creation time to ensure proper order
      validMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messages[conversationId] = validMessages;
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
    _pendingAttachments.remove(
      conversationId,
    ); // Also clear pending attachments
    _replyingToMessages.remove(conversationId); // Clear reply state
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
    _pendingAttachments.clear(); // Also clear pending attachments
    _replyingToMessages.clear(); // Clear reply state
    _currentUser = null;
    _isLoading = false;
    _error = null;
    notifyListeners();
  }

  void _updateConversationLastMessage(String conversationId, Message message) {
    final conversationIndex = _conversations.indexWhere(
      (c) => c.id == conversationId,
    );

    if (conversationIndex != -1) {
      final conversation = _conversations[conversationIndex];

      // Only update if message is valid and not empty
      if (!_isValidMessage(message)) {
        return;
      }

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

      // For text messages, ensure content is not empty or just whitespace
      if (message.type == 'text' && lastMessage.trim().isEmpty) {
        return; // Don't update conversation with empty message
      }

      // Increment unread count if message is not from current user
      int newUnreadCount = conversation.unreadCount;
      if (message.sender != _currentUser?.id) {
        newUnreadCount++;
      }

      final updatedConversation = conversation.copyWith(
        lastMessage: lastMessage,
        lastActivity: message.createdAt,
        lastMessageType: message.type,
        lastMessageSender: message.sender,
        unreadCount: newUnreadCount,
        updatedAt: DateTime.now(),
      );

      _conversations[conversationIndex] = updatedConversation;
      _sortConversations();
    }
  }

  Future<void> sendMessage({
    required String conversationId,
    required String content,
    String type = 'text',
    String? replyTo,
  }) async {
    try {
      // If replyTo is not provided, check if we're replying to a message in this conversation
      String? finalReplyTo = replyTo;
      if (finalReplyTo == null && isReplyingTo(conversationId)) {
        finalReplyTo = getReplyToMessage(conversationId)?.id;
        print('DEBUG: Auto-detected replyTo: $finalReplyTo');
      } else if (finalReplyTo != null) {
        print('DEBUG: Using provided replyTo: $finalReplyTo');
      } else {
        print('DEBUG: No reply state found for conversation: $conversationId');
      }

      // Send via WebSocket only
      _webSocketService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        replyTo: finalReplyTo,
      );

      // Clear reply state if we used it
      if (finalReplyTo != null && isReplyingTo(conversationId)) {
        clearReplyToMessage(conversationId);
        print('DEBUG: Cleared reply state for conversation: $conversationId');
      }
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

  // Upload file and add to pending attachments (don't send yet)
  Future<void> addPendingAttachment({
    required String conversationId,
    required File file,
    required String
    type, // This is now just a hint, we'll use API response type
  }) async {
    try {
      _isLoading = true;
      notifyListeners();

      // Upload file first and get file info
      final uploadResult = await ApiService.uploadMessageFile(
        file,
        conversationId,
      );

      // Extract file info from upload result
      final fileUrl = uploadResult['url'] as String;
      final fileName = uploadResult['name'] as String;
      final fileSize = uploadResult['size'] as int;
      final mimeType = uploadResult['mimetype'] as String;

      // Use the type from API response instead of frontend type
      final apiType = uploadResult['type'] as String; // "VIDEO", "IMAGE", etc.

      // Create attachment data
      final attachment = {
        'name': fileName,
        'url': fileUrl,
        'type': apiType
            .toLowerCase(), // Convert to lowercase: "video", "image", etc.
        'size': fileSize,
        'mimeType': mimeType,
        'originalFile': file, // Keep reference to original file for preview
      };

      // Add to pending attachments
      if (!_pendingAttachments.containsKey(conversationId)) {
        _pendingAttachments[conversationId] = [];
      }
      _pendingAttachments[conversationId]!.add(attachment);

      _isLoading = false;
      notifyListeners();
    } catch (e) {
      _isLoading = false;
      _error = 'Failed to upload file: $e';
      notifyListeners();
    }
  }

  // Send message with pending attachments
  Future<void> sendMessageWithPendingAttachments({
    required String conversationId,
    required String content,
    String? replyTo,
  }) async {
    try {
      final attachments = _pendingAttachments[conversationId] ?? [];

      // If replyTo is not provided, check if we're replying to a message in this conversation
      String? finalReplyTo = replyTo;
      if (finalReplyTo == null && isReplyingTo(conversationId)) {
        finalReplyTo = getReplyToMessage(conversationId)?.id;
      }

      if (attachments.isEmpty) {
        // No attachments, send normal text message with optional reply
        await sendMessage(
          conversationId: conversationId,
          content: content,
          replyTo: finalReplyTo,
        );

        // Clear reply state if we used it
        if (finalReplyTo != null && isReplyingTo(conversationId)) {
          clearReplyToMessage(conversationId);
        }
        return;
      }

      // Prepare attachments for WebSocket (remove originalFile)
      final cleanAttachments = attachments.map((attachment) {
        final clean = Map<String, dynamic>.from(attachment);
        clean.remove('originalFile'); // Remove file reference
        return clean;
      }).toList();

      // Determine message type based on attachments from API response
      String messageType = 'text';
      if (cleanAttachments.isNotEmpty) {
        final firstAttachmentType = cleanAttachments.first['type']
            .toString()
            .toLowerCase();

        // Map API types to message types
        switch (firstAttachmentType) {
          case 'image':
            messageType = 'image';
            break;
          case 'video':
            messageType = 'file'; // Video is treated as file in message type
            break;
          case 'audio':
            messageType = 'file'; // Audio is treated as file in message type
            break;
          case 'file':
          case 'document':
          default:
            messageType = 'file';
            break;
        }
      }

      // Send message with attachments and optional reply via WebSocket
      _webSocketService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: messageType,
        replyTo: finalReplyTo,
        attachments: cleanAttachments,
      );

      // Clear pending attachments and reply state after sending
      _pendingAttachments.remove(conversationId);
      if (finalReplyTo != null && isReplyingTo(conversationId)) {
        clearReplyToMessage(conversationId);
      }
      notifyListeners();
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  // Remove a pending attachment
  void removePendingAttachment(String conversationId, int index) {
    final attachments = _pendingAttachments[conversationId];
    if (attachments != null && index >= 0 && index < attachments.length) {
      attachments.removeAt(index);
      if (attachments.isEmpty) {
        _pendingAttachments.remove(conversationId);
      }
      notifyListeners();
    }
  }

  // Clear all pending attachments for a conversation
  void clearPendingAttachments(String conversationId) {
    _pendingAttachments.remove(conversationId);
    notifyListeners();
  }

  // Get pending attachments for a conversation
  List<Map<String, dynamic>> getPendingAttachments(String conversationId) {
    return _pendingAttachments[conversationId] ?? [];
  }

  // Check if conversation has pending attachments
  bool hasPendingAttachments(String conversationId) {
    final attachments = _pendingAttachments[conversationId];
    return attachments != null && attachments.isNotEmpty;
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
        // For direct conversations, check if participants match exactly
        if (type == 'direct' && conversation.participants.length == 2) {
          final conversationParticipants = conversation.participants.toSet();
          final targetParticipants = participants.toSet();

          if (conversationParticipants.length == targetParticipants.length &&
              conversationParticipants.containsAll(targetParticipants)) {
            return conversation;
          }
        }
        // For group conversations, check if exact same participants
        else if (type == 'group') {
          final conversationParticipants = conversation.participants.toSet();
          final targetParticipants = participants.toSet();

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

  // Get user display name (try fullName first, then username, fallback to ID)
  String getUserDisplayName(String userId) {
    final user = _userCache[userId];
    if (user != null) {
      return user.fullName?.isNotEmpty == true
          ? user.fullName!
          : user.username.isNotEmpty
          ? user.username
          : userId;
    }
    return userId; // Fallback to user ID if not in cache
  }

  // Get user avatar URL
  String? getUserAvatar(String userId) {
    final user = _userCache[userId];
    return user?.avatar;
  }

  // Pre-load users for conversation participants to avoid loading delays
  Future<void> preloadConversationUsers(String conversationId) async {
    final conversation = getConversationById(conversationId);
    if (conversation == null) return;

    // Load all participants who aren't already cached
    final uncachedParticipants = conversation.participants
        .where((id) => !_userCache.containsKey(id))
        .toList();

    for (final userId in uncachedParticipants) {
      await getUser(userId); // This will cache the user
    }
  }

  // Load users for messages in conversation (for sender info)
  Future<void> preloadMessageSenders(String conversationId) async {
    final messages = _messages[conversationId] ?? [];
    final senderIds = messages
        .map((m) => m.sender)
        .where((senderId) => !_userCache.containsKey(senderId))
        .toSet()
        .toList();

    for (final senderId in senderIds) {
      await getUser(senderId);
    }
  }

  // ==================== REPLY TO MESSAGE METHODS ====================

  // Set message to reply to for a conversation
  void setReplyToMessage(String conversationId, Message message) {
    _replyingToMessages[conversationId] = message;
    print(
      'DEBUG: Set reply to message: ${message.id} in conversation: $conversationId',
    );
    notifyListeners();
  }

  // Clear reply state for a conversation
  void clearReplyToMessage(String conversationId) {
    final removedMessage = _replyingToMessages.remove(conversationId);
    print(
      'DEBUG: Cleared reply to message: ${removedMessage?.id} from conversation: $conversationId',
    );
    notifyListeners();
  }

  // Get the message being replied to for a conversation
  Message? getReplyToMessage(String conversationId) {
    return _replyingToMessages[conversationId];
  }

  // Check if currently replying to a message in a conversation
  bool isReplyingTo(String conversationId) {
    return _replyingToMessages.containsKey(conversationId) &&
        _replyingToMessages[conversationId] != null;
  }

  // Get replied message by ID (for displaying reply context)
  Message? getRepliedMessage(String conversationId, String messageId) {
    final messages = _messages[conversationId] ?? [];
    try {
      return messages.firstWhere((message) => message.id == messageId);
    } catch (e) {
      return null;
    }
  }

  // Get reply chain depth (for nested replies)
  int getReplyChainDepth(String conversationId, String messageId) {
    int depth = 0;
    String? currentMessageId = messageId;
    final messages = _messages[conversationId] ?? [];

    while (currentMessageId != null && depth < 10) {
      // Prevent infinite loops
      final message = messages
          .where((m) => m.id == currentMessageId)
          .firstOrNull;
      if (message?.replyTo != null) {
        depth++;
        currentMessageId = message!.replyTo;
      } else {
        break;
      }
    }

    return depth;
  }

  // Get the original message in a reply chain (root message)
  Message? getOriginalMessage(String conversationId, String messageId) {
    String? currentMessageId = messageId;
    final messages = _messages[conversationId] ?? [];
    Message? originalMessage;
    int depth = 0;

    while (currentMessageId != null && depth < 10) {
      // Prevent infinite loops
      final message = messages
          .where((m) => m.id == currentMessageId)
          .firstOrNull;
      if (message != null) {
        originalMessage = message;
        if (message.replyTo != null) {
          currentMessageId = message.replyTo;
          depth++;
        } else {
          break;
        }
      } else {
        break;
      }
    }

    return originalMessage;
  }

  // Get all replies to a specific message
  List<Message> getRepliesToMessage(String conversationId, String messageId) {
    final messages = _messages[conversationId] ?? [];
    return messages.where((message) => message.replyTo == messageId).toList();
  }

  // Check if a message has replies
  bool hasReplies(String conversationId, String messageId) {
    final messages = _messages[conversationId] ?? [];
    return messages.any((message) => message.replyTo == messageId);
  }

  // Get reply count for a message
  int getReplyCount(String conversationId, String messageId) {
    final messages = _messages[conversationId] ?? [];
    return messages.where((message) => message.replyTo == messageId).length;
  }

  // Enhanced send message method with reply support
  Future<void> sendReplyMessage({
    required String conversationId,
    required String content,
    required String replyToMessageId,
    String type = 'text',
  }) async {
    try {
      // Send via WebSocket with reply
      _webSocketService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: type,
        replyTo: replyToMessageId,
      );

      // Clear reply state after sending
      clearReplyToMessage(conversationId);
    } catch (e) {
      _error = 'Failed to send reply: $e';
      notifyListeners();
    }
  }

  // Enhanced send message with pending attachments and reply support
  Future<void> sendMessageWithPendingAttachmentsAndReply({
    required String conversationId,
    required String content,
    String? replyToMessageId,
  }) async {
    try {
      final attachments = _pendingAttachments[conversationId] ?? [];

      // Prepare attachments for WebSocket (remove originalFile)
      final cleanAttachments = attachments.map((attachment) {
        final clean = Map<String, dynamic>.from(attachment);
        clean.remove('originalFile'); // Remove file reference
        return clean;
      }).toList();

      // Determine message type based on attachments
      String messageType = 'text';
      if (cleanAttachments.isNotEmpty) {
        final firstAttachmentType = cleanAttachments.first['type']
            .toString()
            .toLowerCase();

        switch (firstAttachmentType) {
          case 'image':
            messageType = 'image';
            break;
          case 'video':
          case 'audio':
          case 'file':
          case 'document':
          default:
            messageType = 'file';
            break;
        }
      }

      // Send message with attachments and optional reply via WebSocket
      _webSocketService.sendMessage(
        conversationId: conversationId,
        content: content,
        type: messageType,
        replyTo: replyToMessageId,
        attachments: cleanAttachments.isNotEmpty ? cleanAttachments : null,
      );

      // Clear pending attachments and reply state after sending
      _pendingAttachments.remove(conversationId);
      if (replyToMessageId != null) {
        clearReplyToMessage(conversationId);
      }

      notifyListeners();
    } catch (e) {
      _error = 'Failed to send message: $e';
      notifyListeners();
    }
  }

  // ==================== END REPLY TO MESSAGE METHODS ====================

  @override
  void dispose() {
    // Unsubscribe from conversation list updates
    _webSocketService.unsubscribeFromConversationList();
    // Dispose WebSocket service
    _webSocketService.dispose();
    super.dispose();
  }
}
