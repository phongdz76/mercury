import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/chat_message_widgets.dart';

class ChatMessageList extends StatefulWidget {
  final Conversation conversation;
  final ScrollController scrollController;
  final VoidCallback onRefresh;
  final Function(String) onScrollToMessage;

  const ChatMessageList({
    super.key,
    required this.conversation,
    required this.scrollController,
    required this.onRefresh,
    required this.onScrollToMessage,
  });

  @override
  State<ChatMessageList> createState() => _ChatMessageListState();
}

class _ChatMessageListState extends State<ChatMessageList> {
  int _previousMessageCount = 0;

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (widget.scrollController.hasClients && mounted) {
        widget.scrollController.animateTo(
          widget.scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages[widget.conversation.id] ?? [];

        // Auto-scroll when new messages arrive (only if user is near bottom)
        if (messages.length > _previousMessageCount) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            if (widget.scrollController.hasClients) {
              final threshold =
                  widget.scrollController.position.maxScrollExtent - 200;
              final isNearBottom = widget.scrollController.offset >= threshold;

              if (isNearBottom || _previousMessageCount == 0) {
                _scrollToBottom();
              }
            }
          });
        }
        _previousMessageCount = messages.length;

        if (messages.isEmpty) {
          return const Center(child: Text(AppStrings.noMessages));
        }

        return RefreshIndicator(
          onRefresh: () async => widget.onRefresh(),
          child: ListView.builder(
            controller: widget.scrollController,
            padding: const EdgeInsets.all(8),
            itemCount: messages.length,
            itemBuilder: (context, index) {
              final message = messages[index];
              return ChatMessageWidget(
                message: message,
                chatProvider: chatProvider,
                conversation: widget.conversation,
                onScrollToMessage: () => widget.onScrollToMessage(message.id),
              );
            },
          ),
        );
      },
    );
  }
}

class TypingIndicatorWidget extends StatelessWidget {
  final String conversationId;

  const TypingIndicatorWidget({super.key, required this.conversationId});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final isTyping = chatProvider.typingUsers[conversationId] ?? false;
        return AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          height: isTyping ? 40 : 0,
          padding: const EdgeInsets.symmetric(horizontal: 16),
          child: isTyping
              ? Row(
                  children: [
                    Icon(
                      Icons.more_horiz_rounded,
                      color: colorScheme.onSurfaceVariant,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      AppStrings.someonTyping,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                  ],
                )
              : null,
        );
      },
    );
  }
}
