import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../widgets/user_avatar.dart';

class ChatScreenBloc extends StatefulWidget {
  final Conversation conversation;

  const ChatScreenBloc({super.key, required this.conversation});

  @override
  State<ChatScreenBloc> createState() => _ChatScreenBlocState();
}

class _ChatScreenBlocState extends State<ChatScreenBloc> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    // Load messages when screen opens
    context.read<MessageBloc>().add(LoadMessages(widget.conversation.id));
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    // Clear messages when leaving chat
    context.read<MessageBloc>().add(ClearMessages(widget.conversation.id));
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      context.read<MessageBloc>().add(
        SendMessage(
          conversationId: widget.conversation.id,
          content: content,
          type: 'text',
        ),
      );
      _messageController.clear();
    }
  }

  void _onTypingChanged(String value) {
    final isTyping = value.isNotEmpty;
    if (_isTyping != isTyping) {
      setState(() {
        _isTyping = isTyping;
      });
      context.read<MessageBloc>().add(
        SendTyping(widget.conversation.id, isTyping),
      );
    }
  }

  void _scrollToBottom() {
    if (_scrollController.hasClients) {
      _scrollController.animateTo(
        _scrollController.position.maxScrollExtent,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        title: Row(
          children: [
            UserAvatar(
              displayName: widget.conversation.title ?? 'User',
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.conversation.title ?? 'Chat',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  BlocBuilder<MessageBloc, MessageState>(
                    builder: (context, state) {
                      if (state is MessageLoaded) {
                        final isTyping = state.isTypingInConversation(
                          widget.conversation.id,
                        );
                        if (isTyping) {
                          return Text(
                            'Typing...',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(color: colorScheme.primary),
                          );
                        }
                      }
                      return Text(
                        'Online',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          color: colorScheme.onSurfaceVariant,
                        ),
                      );
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          Expanded(
            child: BlocConsumer<MessageBloc, MessageState>(
              listener: (context, state) {
                if (state is MessageError) {
                  ScaffoldMessenger.of(
                    context,
                  ).showSnackBar(SnackBar(content: Text(state.error)));
                } else if (state is MessageLoaded) {
                  // Auto-scroll to bottom when new messages arrive
                  WidgetsBinding.instance.addPostFrameCallback((_) {
                    _scrollToBottom();
                  });
                }
              },
              builder: (context, state) {
                if (state is MessageLoading) {
                  return const Center(child: CircularProgressIndicator());
                } else if (state is MessageError) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${state.error}'),
                        ElevatedButton(
                          onPressed: () {
                            context.read<MessageBloc>().add(
                              LoadMessages(widget.conversation.id),
                            );
                          },
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                } else if (state is MessageLoaded) {
                  final messages = state.getMessagesForConversation(
                    widget.conversation.id,
                  );

                  if (messages.isEmpty) {
                    return const Center(
                      child: Text('No messages yet. Start the conversation!'),
                    );
                  }

                  return ListView.builder(
                    controller: _scrollController,
                    padding: const EdgeInsets.all(16),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[index];
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: _buildMessageBubble(message),
                      );
                    },
                  );
                }

                return const Center(child: Text('Start chatting!'));
              },
            ),
          ),
          _buildMessageInput(),
        ],
      ),
    );
  }

  Widget _buildMessageBubble(Message message) {
    final colorScheme = Theme.of(context).colorScheme;
    final isMe =
        message.sender ==
        'current_user_id'; // Replace with actual current user ID

    return Row(
      mainAxisAlignment: isMe ? MainAxisAlignment.end : MainAxisAlignment.start,
      children: [
        if (!isMe) ...[
          UserAvatar(displayName: 'User', size: 24),
          const SizedBox(width: 8),
        ],
        Flexible(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: isMe
                  ? colorScheme.primaryContainer
                  : colorScheme.surfaceVariant,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  message.content,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: isMe
                        ? colorScheme.onPrimaryContainer
                        : colorScheme.onSurfaceVariant,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatTime(message.createdAt),
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: isMe
                        ? colorScheme.onPrimaryContainer.withOpacity(0.7)
                        : colorScheme.onSurfaceVariant.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ),
        ),
        if (isMe) ...[
          const SizedBox(width: 8),
          UserAvatar(displayName: 'Me', size: 24),
        ],
      ],
    );
  }

  Widget _buildMessageInput() {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(
          top: BorderSide(color: colorScheme.outlineVariant, width: 1),
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _messageController,
              onChanged: _onTypingChanged,
              decoration: InputDecoration(
                hintText: 'Type a message...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(24),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: colorScheme.surfaceVariant,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 12),
          BlocBuilder<MessageBloc, MessageState>(
            builder: (context, state) {
              final isSending =
                  state is MessageSending &&
                  state.conversationId == widget.conversation.id;

              return FloatingActionButton.small(
                onPressed: isSending ? null : _sendMessage,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: isSending
                    ? SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: colorScheme.onPrimary,
                        ),
                      )
                    : const Icon(Icons.send_rounded),
              );
            },
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Now';
    }
  }
}
