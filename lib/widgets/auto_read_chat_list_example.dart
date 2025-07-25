import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';
import 'message_read_status_widget.dart';

class AutoReadChatListExample extends StatefulWidget {
  final String conversationId;

  const AutoReadChatListExample({Key? key, required this.conversationId})
    : super(key: key);

  @override
  State<AutoReadChatListExample> createState() =>
      _AutoReadChatListExampleState();
}

class _AutoReadChatListExampleState extends State<AutoReadChatListExample> {
  final ScrollController _scrollController = ScrollController();
  final List<GlobalKey> _messageKeys = [];

  @override
  void initState() {
    super.initState();

    // Add scroll listener to detect visible messages
    _scrollController.addListener(_onScroll);
  }

  @override
  void dispose() {
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _onScroll() {
    // Check which messages are visible and mark them as read
    _checkVisibleMessages();
  }

  void _checkVisibleMessages() {
    if (!mounted) return;

    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final messages = chatProvider.messages[widget.conversationId] ?? [];

    final visibleMessageIds = <String>[];

    for (int i = 0; i < _messageKeys.length && i < messages.length; i++) {
      final key = _messageKeys[i];
      final renderObject = key.currentContext?.findRenderObject();

      if (renderObject != null) {
        final renderBox = renderObject as RenderBox;
        final position = renderBox.localToGlobal(Offset.zero);
        final size = renderBox.size;

        // Check if message is visible in viewport
        final viewportHeight = MediaQuery.of(context).size.height;
        final isVisible =
            position.dy < viewportHeight && position.dy + size.height > 0;

        if (isVisible) {
          visibleMessageIds.add(messages[i].id);
        }
      }
    }

    // Mark visible messages as read
    if (visibleMessageIds.isNotEmpty) {
      chatProvider.markMessagesAsReadWhenVisible(
        widget.conversationId,
        visibleMessageIds,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final messages = chatProvider.messages[widget.conversationId] ?? [];

        // Update message keys list
        while (_messageKeys.length < messages.length) {
          _messageKeys.add(GlobalKey());
        }

        return Column(
          children: [
            // Unread messages indicator
            _buildUnreadIndicator(chatProvider),

            // Messages list
            Expanded(
              child: ListView.builder(
                controller: _scrollController,
                itemCount: messages.length,
                itemBuilder: (context, index) {
                  final message = messages[index];
                  return _buildMessageItem(message, index, chatProvider);
                },
              ),
            ),

            // Mark all as read button
            _buildMarkAllAsReadButton(chatProvider),
          ],
        );
      },
    );
  }

  Widget _buildUnreadIndicator(ChatProvider chatProvider) {
    final readStatus = chatProvider.getConversationReadStatus(
      widget.conversationId,
    );
    final unreadCount = readStatus['unreadCount'] as int;

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      color: Colors.blue.withOpacity(0.1),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.mark_chat_unread, size: 16, color: Colors.blue),
          const SizedBox(width: 8),
          Text(
            '$unreadCount unread message${unreadCount > 1 ? 's' : ''}',
            style: const TextStyle(
              color: Colors.blue,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(
    Message message,
    int index,
    ChatProvider chatProvider,
  ) {
    final isCurrentUser = message.sender == chatProvider.currentUser?.id;
    final isRead = chatProvider.isMessageReadByCurrentUser(
      message.id,
      widget.conversationId,
    );

    return Container(
      key: _messageKeys[index],
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 8),
      child: Row(
        mainAxisAlignment: isCurrentUser
            ? MainAxisAlignment.end
            : MainAxisAlignment.start,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Message bubble
          Container(
            constraints: BoxConstraints(
              maxWidth: MediaQuery.of(context).size.width * 0.7,
            ),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: isCurrentUser ? Colors.blue : Colors.grey[300],
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Message content
                Text(
                  message.content,
                  style: TextStyle(
                    color: isCurrentUser ? Colors.white : Colors.black,
                  ),
                ),

                const SizedBox(height: 4),

                // Message time and read status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      _formatTime(message.createdAt),
                      style: TextStyle(
                        fontSize: 10,
                        color: isCurrentUser
                            ? Colors.white70
                            : Colors.grey[600],
                      ),
                    ),

                    if (isCurrentUser) ...[
                      const SizedBox(width: 8),
                      MessageReadStatusWidget(
                        message: message,
                        conversationId: widget.conversationId,
                      ),
                    ],
                  ],
                ),
              ],
            ),
          ),

          // Unread indicator for other users' messages
          if (!isCurrentUser && !isRead)
            Container(
              margin: const EdgeInsets.only(left: 8, top: 8),
              width: 8,
              height: 8,
              decoration: const BoxDecoration(
                color: Colors.blue,
                shape: BoxShape.circle,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMarkAllAsReadButton(ChatProvider chatProvider) {
    final unreadCount = chatProvider.getUnreadMessagesCount(
      widget.conversationId,
    );

    if (unreadCount == 0) {
      return const SizedBox.shrink();
    }

    return Container(
      padding: const EdgeInsets.all(8),
      child: ElevatedButton.icon(
        onPressed: () {
          chatProvider.markAllMessagesAsRead(widget.conversationId);
        },
        icon: const Icon(Icons.done_all),
        label: const Text('Mark all as read'),
        style: ElevatedButton.styleFrom(
          backgroundColor: Colors.blue,
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final messageDate = DateTime(dateTime.year, dateTime.month, dateTime.day);

    if (messageDate == today) {
      return '${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    } else {
      return '${messageDate.day}/${messageDate.month} ${dateTime.hour.toString().padLeft(2, '0')}:${dateTime.minute.toString().padLeft(2, '0')}';
    }
  }
}
