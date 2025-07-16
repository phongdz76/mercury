import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ChatProvider>().loadMessages(widget.conversation.id);
    });
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(
        conversationId: widget.conversation.id,
        content: content,
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping(String text) {
    final isCurrentlyTyping = text.isNotEmpty;
    if (_isTyping != isCurrentlyTyping) {
      _isTyping = isCurrentlyTyping;
      context.read<ChatProvider>().sendTyping(
        widget.conversation.id,
        _isTyping,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          widget.conversation.title ??
              (widget.conversation.type == ApiConstants.conversationTypeDirect
                  ? AppStrings.directChat
                  : AppStrings.groupChat),
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Icon(
                chatProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                color: chatProvider.isConnected ? Colors.white : Colors.red,
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final messages =
                    chatProvider.messages[widget.conversation.id] ?? [];

                if (messages.isEmpty) {
                  return const Center(child: Text(AppStrings.noMessages));
                }

                return ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(8),
                  itemCount: messages.length,
                  itemBuilder: (context, index) {
                    final message = messages[index];
                    return _buildMessageItem(message, chatProvider);
                  },
                );
              },
            ),
          ),

          // Typing indicator
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final isTyping =
                  chatProvider.typingUsers[widget.conversation.id] ?? false;
              return AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                height: isTyping ? 40 : 0,
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: isTyping
                    ? const Row(
                        children: [
                          Icon(Icons.more_horiz, color: Colors.grey),
                          SizedBox(width: 8),
                          Text(
                            AppStrings.someonTyping,
                            style: TextStyle(color: Colors.grey),
                          ),
                        ],
                      )
                    : null,
              );
            },
          ),

          // Message input
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              children: [
                Expanded(
                  child: TextField(
                    controller: _messageController,
                    decoration: const InputDecoration(
                      hintText: AppStrings.typeMessage,
                      border: OutlineInputBorder(),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 8,
                      ),
                    ),
                    onChanged: _onTyping,
                    onSubmitted: (_) => _sendMessage(),
                    maxLines: null,
                  ),
                ),
                const SizedBox(width: 8),
                IconButton(
                  onPressed: _sendMessage,
                  icon: const Icon(Icons.send),
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, ChatProvider chatProvider) {
    final isCurrentUser = message.sender == chatProvider.currentUser?.id;

    return Align(
      alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.all(12),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.of(context).size.width * 0.7,
        ),
        decoration: BoxDecoration(
          color: isCurrentUser ? Colors.blue : Colors.grey[200],
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (!isCurrentUser)
              Text(
                message.sender,
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.grey,
                ),
              ),

            Text(
              message.content,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),

            const SizedBox(height: 4),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  Utils.formatTime(message.createdAt),
                  style: TextStyle(
                    fontSize: 10,
                    color: isCurrentUser ? Colors.white70 : Colors.grey,
                  ),
                ),

                if (message.isEdited) ...[
                  const SizedBox(width: 4),
                  Icon(
                    Icons.edit,
                    size: 12,
                    color: isCurrentUser ? Colors.white70 : Colors.grey,
                  ),
                ],

                if (isCurrentUser) ...[
                  const SizedBox(width: 4),
                  Icon(Icons.check, size: 12, color: Colors.white70),
                ],
              ],
            ),
          ],
        ),
      ),
    );
  }
}
