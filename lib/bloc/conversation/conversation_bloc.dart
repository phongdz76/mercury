import 'dart:async';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../../models/conversation.dart';
import '../../models/websocket_event.dart';
import '../../services/api_service.dart';
import '../../services/websocket_service.dart';
import 'conversation_event.dart';
import 'conversation_state.dart';

class ConversationBloc extends Bloc<ConversationEvent, ConversationState> {
  final WebSocketService _webSocketService = WebSocketService();
  late StreamSubscription _webSocketSubscription;
  List<Conversation> _conversations = [];

  ConversationBloc() : super(ConversationInitial()) {
    _initializeWebSocketListener();

    on<LoadConversations>(_onLoadConversations);
    on<RefreshConversations>(_onRefreshConversations);
    on<CreateConversation>(_onCreateConversation);
    on<ConversationUpdated>(_onConversationUpdated);
    on<ConversationDeleted>(_onConversationDeleted);
    on<MarkConversationAsRead>(_onMarkConversationAsRead);
    on<MuteConversation>(_onMuteConversation);
    on<ArchiveConversation>(_onArchiveConversation);
  }

  void _initializeWebSocketListener() {
    _webSocketSubscription = _webSocketService.events.listen(
      (event) {
        _handleWebSocketEvent(event);
      },
      onError: (error) {
        print('WebSocket error in ConversationBloc: $error');
      },
    );
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case 'conversation_created':
        try {
          final conversation = Conversation.fromJson(
            event.data['conversation'],
          );
          add(ConversationUpdated(conversation));
        } catch (e) {
          print('Error handling conversation created: $e');
        }
        break;
      case 'conversation_updated':
        try {
          final conversation = Conversation.fromJson(
            event.data['conversation'],
          );
          add(ConversationUpdated(conversation));
        } catch (e) {
          print('Error handling conversation updated: $e');
        }
        break;
      case 'conversation_deleted':
        final conversationId = event.data['conversationId'] as String?;
        if (conversationId != null) {
          add(ConversationDeleted(conversationId));
        }
        break;
      case 'conversation_list_updated':
        try {
          final conversationData = event.data['conversation'];
          if (conversationData != null) {
            final conversation = Conversation.fromJson(conversationData);
            add(ConversationUpdated(conversation));
          }
        } catch (e) {
          print('Error handling conversation list updated: $e');
        }
        break;
    }
  }

  Future<void> _onLoadConversations(
    LoadConversations event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      emit(ConversationLoading());

      _conversations = await ApiService.getConversations();
      _sortConversations();

      // Subscribe to conversation list updates
      _webSocketService.subscribeToConversationList();

      emit(ConversationLoaded(_conversations));
    } catch (e) {
      emit(ConversationError('Failed to load conversations: $e'));
    }
  }

  Future<void> _onRefreshConversations(
    RefreshConversations event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      _conversations = await ApiService.getConversations();
      _sortConversations();

      emit(ConversationLoaded(_conversations));
    } catch (e) {
      emit(ConversationError('Failed to refresh conversations: $e'));
    }
  }

  Future<void> _onCreateConversation(
    CreateConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      emit(ConversationCreating());

      final conversation = await ApiService.createConversation(
        type: event.type,
        participants: event.participants,
        title: event.title,
      );

      _conversations.add(conversation);
      _sortConversations();

      emit(ConversationCreated(conversation));
      emit(ConversationLoaded(_conversations));
    } catch (e) {
      emit(ConversationError('Failed to create conversation: $e'));
    }
  }

  Future<void> _onConversationUpdated(
    ConversationUpdated event,
    Emitter<ConversationState> emit,
  ) async {
    final conversation = event.conversation;
    final index = _conversations.indexWhere((c) => c.id == conversation.id);

    if (index != -1) {
      _conversations[index] = conversation;
    } else {
      _conversations.add(conversation);
    }

    _sortConversations();

    if (state is ConversationLoaded) {
      emit(ConversationLoaded(List.from(_conversations)));
    }
  }

  Future<void> _onConversationDeleted(
    ConversationDeleted event,
    Emitter<ConversationState> emit,
  ) async {
    _conversations.removeWhere((c) => c.id == event.conversationId);

    if (state is ConversationLoaded) {
      emit(ConversationLoaded(List.from(_conversations)));
    }
  }

  Future<void> _onMarkConversationAsRead(
    MarkConversationAsRead event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final index = _conversations.indexWhere(
        (c) => c.id == event.conversationId,
      );
      if (index != -1) {
        final conversation = _conversations[index];
        if (conversation.unreadCount > 0) {
          final updatedConversation = conversation.copyWith(unreadCount: 0);
          _conversations[index] = updatedConversation;

          // Notify server via WebSocket
          _webSocketService.markConversationAsRead(event.conversationId);

          if (state is ConversationLoaded) {
            emit(ConversationLoaded(List.from(_conversations)));
          }
        }
      }
    } catch (e) {
      emit(ConversationError('Failed to mark conversation as read: $e'));
    }
  }

  Future<void> _onMuteConversation(
    MuteConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final index = _conversations.indexWhere(
        (c) => c.id == event.conversationId,
      );
      if (index != -1) {
        final conversation = _conversations[index];
        final updatedConversation = conversation.copyWith(isMuted: event.mute);
        _conversations[index] = updatedConversation;

        // Notify server via WebSocket
        _webSocketService.muteConversation(event.conversationId, event.mute);

        if (state is ConversationLoaded) {
          emit(ConversationLoaded(List.from(_conversations)));
        }
      }
    } catch (e) {
      emit(ConversationError('Failed to mute conversation: $e'));
    }
  }

  Future<void> _onArchiveConversation(
    ArchiveConversation event,
    Emitter<ConversationState> emit,
  ) async {
    try {
      final index = _conversations.indexWhere(
        (c) => c.id == event.conversationId,
      );
      if (index != -1) {
        final conversation = _conversations[index];
        final updatedConversation = conversation.copyWith(
          isArchived: event.archive,
        );
        _conversations[index] = updatedConversation;
        _sortConversations();

        // Notify server via WebSocket
        _webSocketService.archiveConversation(
          event.conversationId,
          event.archive,
        );

        if (state is ConversationLoaded) {
          emit(ConversationLoaded(List.from(_conversations)));
        }
      }
    } catch (e) {
      emit(ConversationError('Failed to archive conversation: $e'));
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

  @override
  Future<void> close() {
    _webSocketSubscription.cancel();
    _webSocketService.unsubscribeFromConversationList();
    return super.close();
  }
}
