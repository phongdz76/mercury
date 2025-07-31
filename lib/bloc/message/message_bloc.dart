import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/message.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import '../../models/websocket_event.dart';
import 'message_event.dart';
import 'message_state.dart';

class MessageBloc extends Bloc<MessageEvent, MessageState> {
  final WebSocketService _webSocketService = WebSocketService();
  late StreamSubscription _webSocketSubscription;
  final Map<String, List<Message>> _messages = {};
  final Map<String, bool> _typingUsers = {};

  MessageBloc() : super(MessageInitial()) {
    _initializeWebSocketListener();

    on<LoadMessages>(_onLoadMessages);
    on<SendMessage>(_onSendMessage);
    on<MessageReceived>(_onMessageReceived);
    on<MarkMessageAsRead>(_onMarkMessageAsRead);
    on<SendTyping>(_onSendTyping);
    on<TypingStatusChanged>(_onTypingStatusChanged);
    on<ClearMessages>(_onClearMessages);
  }

  void _initializeWebSocketListener() {
    _webSocketSubscription = _webSocketService.events.listen(
      (event) {
        _handleWebSocketEvent(event);
      },
      onError: (error) {
        // Handle WebSocket errors - could emit an error state if needed
        print('WebSocket error in MessageBloc: $error');
      },
    );
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case 'message':
        try {
          final message = Message.fromJson(event.data);
          add(MessageReceived(message));
        } catch (e) {
          print('Error parsing message: $e');
        }
        break;
      case 'typing':
        final conversationId = event.conversationId;
        final isTyping = event.data['isTyping'] ?? false;
        if (conversationId != null) {
          add(TypingStatusChanged(conversationId, isTyping));
        }
        break;
    }
  }

  Future<void> _onLoadMessages(
    LoadMessages event,
    Emitter<MessageState> emit,
  ) async {
    try {
      emit(MessageLoading());

      final messages = await ApiService.getMessages(event.conversationId);

      // Filter out invalid messages
      final validMessages = messages
          .where((message) => _isValidMessage(message))
          .toList();

      // Sort messages by creation time
      validMessages.sort((a, b) => a.createdAt.compareTo(b.createdAt));

      _messages[event.conversationId] = validMessages;

      // Join conversation room for real-time updates
      _webSocketService.joinConversation(event.conversationId);

      emit(
        MessageLoaded(
          messages: Map.from(_messages),
          typingUsers: Map.from(_typingUsers),
        ),
      );
    } catch (e) {
      emit(MessageError('Failed to load messages: $e'));
    }
  }

  Future<void> _onSendMessage(
    SendMessage event,
    Emitter<MessageState> emit,
  ) async {
    try {
      emit(MessageSending(event.conversationId));

      // Send via WebSocket
      _webSocketService.sendMessage(
        conversationId: event.conversationId,
        content: event.content,
        type: event.type,
        replyTo: event.replyTo,
      );

      // The actual message will be received via WebSocket and handled by MessageReceived event
    } catch (e) {
      emit(MessageError('Failed to send message: $e'));
    }
  }

  Future<void> _onMessageReceived(
    MessageReceived event,
    Emitter<MessageState> emit,
  ) async {
    final message = event.message;
    final conversationId = message.conversationId;

    if (!_isValidMessage(message)) {
      return;
    }

    // Initialize messages list if not exists
    if (!_messages.containsKey(conversationId)) {
      _messages[conversationId] = [];
    }

    // Check if message already exists
    final existingMessageIndex = _messages[conversationId]!.indexWhere(
      (m) => m.id == message.id,
    );

    if (existingMessageIndex == -1) {
      // New message, add it
      _messages[conversationId]!.add(message);
      _messages[conversationId]!.sort(
        (a, b) => a.createdAt.compareTo(b.createdAt),
      );
    } else {
      // Message exists, update it
      _messages[conversationId]![existingMessageIndex] = message;
    }

    emit(
      MessageLoaded(
        messages: Map.from(_messages),
        typingUsers: Map.from(_typingUsers),
      ),
    );
  }

  Future<void> _onMarkMessageAsRead(
    MarkMessageAsRead event,
    Emitter<MessageState> emit,
  ) async {
    try {
      _webSocketService.markAsRead(event.conversationId, event.messageId);
    } catch (e) {
      emit(MessageError('Failed to mark message as read: $e'));
    }
  }

  Future<void> _onSendTyping(
    SendTyping event,
    Emitter<MessageState> emit,
  ) async {
    try {
      _webSocketService.sendTyping(event.conversationId, event.isTyping);
    } catch (e) {
      emit(MessageError('Failed to send typing indicator: $e'));
    }
  }

  Future<void> _onTypingStatusChanged(
    TypingStatusChanged event,
    Emitter<MessageState> emit,
  ) async {
    _typingUsers[event.conversationId] = event.isTyping;

    if (state is MessageLoaded) {
      emit(
        (state as MessageLoaded).copyWith(typingUsers: Map.from(_typingUsers)),
      );
    }
  }

  Future<void> _onClearMessages(
    ClearMessages event,
    Emitter<MessageState> emit,
  ) async {
    _messages.remove(event.conversationId);
    _typingUsers.remove(event.conversationId);

    // Leave conversation room
    _webSocketService.leaveConversation(event.conversationId);

    if (state is MessageLoaded) {
      emit(
        (state as MessageLoaded).copyWith(
          messages: Map.from(_messages),
          typingUsers: Map.from(_typingUsers),
        ),
      );
    }
  }

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

  @override
  Future<void> close() {
    _webSocketSubscription.cancel();
    return super.close();
  }
}
