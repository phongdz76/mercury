import 'package:equatable/equatable.dart';
import '../../models/message.dart';

abstract class MessageState extends Equatable {
  const MessageState();

  @override
  List<Object?> get props => [];
}

class MessageInitial extends MessageState {}

class MessageLoading extends MessageState {}

class MessageLoaded extends MessageState {
  final Map<String, List<Message>> messages;
  final Map<String, bool> typingUsers;

  const MessageLoaded({required this.messages, required this.typingUsers});

  @override
  List<Object?> get props => [messages, typingUsers];

  MessageLoaded copyWith({
    Map<String, List<Message>>? messages,
    Map<String, bool>? typingUsers,
  }) {
    return MessageLoaded(
      messages: messages ?? this.messages,
      typingUsers: typingUsers ?? this.typingUsers,
    );
  }

  List<Message> getMessagesForConversation(String conversationId) {
    return messages[conversationId] ?? [];
  }

  bool isTypingInConversation(String conversationId) {
    return typingUsers[conversationId] ?? false;
  }
}

class MessageError extends MessageState {
  final String error;

  const MessageError(this.error);

  @override
  List<Object?> get props => [error];
}

class MessageSending extends MessageState {
  final String conversationId;

  const MessageSending(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class MessageSent extends MessageState {
  final Message message;

  const MessageSent(this.message);

  @override
  List<Object?> get props => [message];
}
