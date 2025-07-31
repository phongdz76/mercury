import 'package:equatable/equatable.dart';
import '../../models/conversation.dart';

abstract class ConversationEvent extends Equatable {
  const ConversationEvent();

  @override
  List<Object?> get props => [];
}

class LoadConversations extends ConversationEvent {}

class RefreshConversations extends ConversationEvent {}

class CreateConversation extends ConversationEvent {
  final String type;
  final List<String> participants;
  final String? title;

  const CreateConversation({
    required this.type,
    required this.participants,
    this.title,
  });

  @override
  List<Object?> get props => [type, participants, title];
}

class ConversationUpdated extends ConversationEvent {
  final Conversation conversation;

  const ConversationUpdated(this.conversation);

  @override
  List<Object?> get props => [conversation];
}

class ConversationDeleted extends ConversationEvent {
  final String conversationId;

  const ConversationDeleted(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MarkConversationAsRead extends ConversationEvent {
  final String conversationId;

  const MarkConversationAsRead(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MuteConversation extends ConversationEvent {
  final String conversationId;
  final bool mute;

  const MuteConversation(this.conversationId, this.mute);

  @override
  List<Object?> get props => [conversationId, mute];
}

class ArchiveConversation extends ConversationEvent {
  final String conversationId;
  final bool archive;

  const ArchiveConversation(this.conversationId, this.archive);

  @override
  List<Object?> get props => [conversationId, archive];
}
