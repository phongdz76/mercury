import 'package:equatable/equatable.dart';
import '../../models/message.dart';

abstract class MessageEvent extends Equatable {
  const MessageEvent();

  @override
  List<Object?> get props => [];
}

class LoadMessages extends MessageEvent {
  final String conversationId;

  const LoadMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}

class SendMessage extends MessageEvent {
  final String conversationId;
  final String content;
  final String type;
  final String? replyTo;

  const SendMessage({
    required this.conversationId,
    required this.content,
    this.type = 'text',
    this.replyTo,
  });

  @override
  List<Object?> get props => [conversationId, content, type, replyTo];
}

class MessageReceived extends MessageEvent {
  final Message message;

  const MessageReceived(this.message);

  @override
  List<Object?> get props => [message];
}

class MarkMessageAsRead extends MessageEvent {
  final String conversationId;
  final String messageId;

  const MarkMessageAsRead(this.conversationId, this.messageId);

  @override
  List<Object?> get props => [conversationId, messageId];
}

class SendTyping extends MessageEvent {
  final String conversationId;
  final bool isTyping;

  const SendTyping(this.conversationId, this.isTyping);

  @override
  List<Object?> get props => [conversationId, isTyping];
}

class TypingStatusChanged extends MessageEvent {
  final String conversationId;
  final bool isTyping;

  const TypingStatusChanged(this.conversationId, this.isTyping);

  @override
  List<Object?> get props => [conversationId, isTyping];
}

class ClearMessages extends MessageEvent {
  final String conversationId;

  const ClearMessages(this.conversationId);

  @override
  List<Object?> get props => [conversationId];
}
