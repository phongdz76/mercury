import 'package:equatable/equatable.dart';
import '../../models/conversation.dart';

abstract class ConversationState extends Equatable {
  const ConversationState();

  @override
  List<Object?> get props => [];
}

class ConversationInitial extends ConversationState {}

class ConversationLoading extends ConversationState {}

class ConversationLoaded extends ConversationState {
  final List<Conversation> conversations;

  const ConversationLoaded(this.conversations);

  @override
  List<Object?> get props => [conversations];

  ConversationLoaded copyWith({List<Conversation>? conversations}) {
    return ConversationLoaded(conversations ?? this.conversations);
  }

  List<Conversation> getActiveConversations() {
    return conversations.where((c) => !c.isArchived && c.isActive).toList();
  }

  List<Conversation> getArchivedConversations() {
    return conversations.where((c) => c.isArchived).toList();
  }

  List<Conversation> getMutedConversations() {
    return conversations.where((c) => c.isMuted).toList();
  }

  List<Conversation> getUnreadConversations() {
    return conversations.where((c) => c.unreadCount > 0).toList();
  }

  int getTotalUnreadCount() {
    return conversations
        .where((c) => !c.isArchived && !c.isMuted)
        .fold(0, (sum, conversation) => sum + conversation.unreadCount);
  }

  Conversation? getConversationById(String conversationId) {
    try {
      return conversations.firstWhere((c) => c.id == conversationId);
    } catch (e) {
      return null;
    }
  }
}

class ConversationError extends ConversationState {
  final String error;

  const ConversationError(this.error);

  @override
  List<Object?> get props => [error];
}

class ConversationCreating extends ConversationState {}

class ConversationCreated extends ConversationState {
  final Conversation conversation;

  const ConversationCreated(this.conversation);

  @override
  List<Object?> get props => [conversation];
}
