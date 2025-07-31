import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/message.dart';
import '../providers/chat_provider.dart';

/// Widget helper để hiển thị reply context trong tin nhắn
class MessageReplyWidget extends StatelessWidget {
  final Message message;
  final String conversationId;
  final VoidCallback? onTap;

  const MessageReplyWidget({
    Key? key,
    required this.message,
    required this.conversationId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    if (message.replyTo == null) {
      return const SizedBox.shrink();
    }

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final repliedMessage = chatProvider.getRepliedMessage(
          conversationId,
          message.replyTo!,
        );

        if (repliedMessage == null) {
          return Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.errorContainer,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.error,
                  width: 3,
                ),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.error_outline,
                  size: 16,
                  color: Theme.of(context).colorScheme.error,
                ),
                const SizedBox(width: 8),
                Text(
                  "Message not found",
                  style: TextStyle(
                    fontStyle: FontStyle.italic,
                    color: Theme.of(context).colorScheme.onErrorContainer,
                  ),
                ),
              ],
            ),
          );
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(bottom: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
              borderRadius: BorderRadius.circular(8),
              border: Border(
                left: BorderSide(
                  color: Theme.of(context).colorScheme.tertiary,
                  width: 3,
                ),
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.reply, size: 14, color: Colors.blue),
                    const SizedBox(width: 4),
                    Text(
                      chatProvider.getUserDisplayName(repliedMessage.sender),
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: Colors.blue,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 2),
                Text(
                  _getMessagePreview(repliedMessage),
                  style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case 'image':
        return '📷 Image';
      case 'file':
        return '📁 File';
      case 'audio':
        return '🎵 Audio';
      case 'video':
        return '🎥 Video';
      case 'location':
        return '📍 Location';
      default:
        return message.content.isEmpty ? 'Message' : message.content;
    }
  }
}

/// Widget để hiển thị reply preview khi đang soạn tin nhắn
class ReplyPreviewWidget extends StatelessWidget {
  final String conversationId;

  const ReplyPreviewWidget({Key? key, required this.conversationId})
    : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final replyingMessage = chatProvider.getReplyToMessage(conversationId);

        if (replyingMessage == null) {
          return const SizedBox.shrink();
        }

        return Container(
          margin: const EdgeInsets.all(8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: const Border(
              left: BorderSide(color: Colors.blue, width: 3),
            ),
          ),
          child: Row(
            children: [
              const Icon(Icons.reply, size: 16, color: Colors.blue),
              const SizedBox(width: 8),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Replying to ${chatProvider.getUserDisplayName(replyingMessage.sender)}",
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      _getMessagePreview(replyingMessage),
                      style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close, size: 16),
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
                onPressed: () {
                  chatProvider.clearReplyToMessage(conversationId);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  String _getMessagePreview(Message message) {
    switch (message.type) {
      case 'image':
        return '📷 Image';
      case 'file':
        return '📁 File';
      case 'audio':
        return '🎵 Audio';
      case 'video':
        return '🎥 Video';
      case 'location':
        return '📍 Location';
      default:
        return message.content.isEmpty ? 'Message' : message.content;
    }
  }
}

/// Widget button để reply tin nhắn
class MessageReplyButton extends StatelessWidget {
  final Message message;
  final String conversationId;

  const MessageReplyButton({
    Key? key,
    required this.message,
    required this.conversationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Hiển thị reply button cho tất cả tin nhắn
        // (có thể reply cả tin nhắn của chính mình)

        return IconButton(
          icon: const Icon(Icons.reply, size: 18),
          padding: EdgeInsets.zero,
          constraints: const BoxConstraints(),
          onPressed: () {
            chatProvider.setReplyToMessage(conversationId, message);
            print('DEBUG: Reply button pressed for message: ${message.id}');

            // Optional: Show snackbar hoặc scroll to input
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  'Replying to ${chatProvider.getUserDisplayName(message.sender)}',
                ),
                duration: const Duration(seconds: 2),
              ),
            );
          },
        );
      },
    );
  }
}

/// Widget hiển thị số lượng replies cho một tin nhắn
class MessageReplyCountWidget extends StatelessWidget {
  final Message message;
  final String conversationId;
  final VoidCallback? onTap;

  const MessageReplyCountWidget({
    Key? key,
    required this.message,
    required this.conversationId,
    this.onTap,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final replyCount = chatProvider.getReplyCount(
          conversationId,
          message.id,
        );

        if (replyCount == 0) {
          return const SizedBox.shrink();
        }

        return GestureDetector(
          onTap: onTap,
          child: Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                const Icon(Icons.reply, size: 12, color: Colors.blue),
                const SizedBox(width: 4),
                Text(
                  '$replyCount ${replyCount == 1 ? 'reply' : 'replies'}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.blue,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
