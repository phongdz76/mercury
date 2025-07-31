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
    return Scaffold(
      appBar: AppBar(
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
                    style: const TextStyle(fontSize: 16),
                  ),
                  BlocBuilder<MessageBloc, MessageState>(
                    builder: (context, state) {
                      if (state is MessageLoaded) {
                        final isTyping = state.isTypingInConversation(
                          widget.conversation.id,
                        );
                        if (isTyping) {
                          return const Text(
                            'Typing...',
                            style: TextStyle(fontSize: 12, color: Colors.green),
                          );
                        }
                      }
                      return const Text(
                        'Online',
                        style: TextStyle(fontSize: 12, color: Colors.grey),
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
                      return _buildMessageBubble(message);
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
    final isMe =
        message.sender ==
        'current_user_id'; // Replace with actual current user ID

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: isMe
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        children: [
          if (!isMe) ...[
            UserAvatar(displayName: 'User', size: 24),
            const SizedBox(width: 8),
          ],
          Flexible(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: isMe ? Colors.blue : Colors.grey[300],
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    message.content,
                    style: TextStyle(color: isMe ? Colors.white : Colors.black),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    _formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isMe ? Colors.white70 : Colors.grey[600],
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
      ),
    );
  }

  Widget _buildMessageInput() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withValues(alpha: 0.1),
            spreadRadius: 1,
            blurRadius: 4,
            offset: const Offset(0, -2),
          ),
        ],
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
                  borderRadius: BorderRadius.circular(25),
                  borderSide: BorderSide.none,
                ),
                filled: true,
                fillColor: Colors.grey[100],
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 10,
                ),
              ),
              onSubmitted: (_) => _sendMessage(),
            ),
          ),
          const SizedBox(width: 8),
          BlocBuilder<MessageBloc, MessageState>(
            builder: (context, state) {
              final isSending =
                  state is MessageSending &&
                  state.conversationId == widget.conversation.id;

              return FloatingActionButton(
                mini: true,
                onPressed: isSending ? null : _sendMessage,
                child: isSending
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.send),
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
