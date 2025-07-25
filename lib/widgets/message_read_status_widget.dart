import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/message.dart';

class MessageReadStatusWidget extends StatelessWidget {
  final Message message;
  final String conversationId;

  const MessageReadStatusWidget({
    Key? key,
    required this.message,
    required this.conversationId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        // Only show read status for messages sent by current user
        if (!chatProvider.shouldShowReadIndicator(message.id, conversationId)) {
          return const SizedBox.shrink();
        }

        final readReceipts = chatProvider.getMessageReadReceipts(
          message.id,
          conversationId,
        );
        final readStatusText = chatProvider.getReadStatusText(
          message.id,
          conversationId,
        );

        return Container(
          padding: const EdgeInsets.only(top: 2),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Read status icon
              Icon(
                readReceipts.isEmpty ? Icons.done : Icons.done_all,
                size: 12,
                color: readReceipts.isEmpty ? Colors.grey : Colors.blue,
              ),
              const SizedBox(width: 4),
              // Read status text
              Text(
                readStatusText,
                style: TextStyle(fontSize: 10, color: Colors.grey[600]),
              ),
              // Show read count if multiple users have read
              if (readReceipts.length > 1)
                GestureDetector(
                  onTap: () => _showReadReceiptDetails(context, readReceipts),
                  child: Container(
                    margin: const EdgeInsets.only(left: 4),
                    child: Icon(
                      Icons.info_outline,
                      size: 12,
                      color: Colors.grey[600],
                    ),
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  void _showReadReceiptDetails(
    BuildContext context,
    List<ReadReceipt> readReceipts,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Read by'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: readReceipts.map((receipt) {
            return Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return FutureBuilder(
                  future: chatProvider.getUser(receipt.userId),
                  builder: (context, snapshot) {
                    final user = snapshot.data;
                    return ListTile(
                      leading: CircleAvatar(
                        child: Text(
                          user?.fullName?.substring(0, 1).toUpperCase() ??
                              user?.username.substring(0, 1).toUpperCase() ??
                              '?',
                        ),
                      ),
                      title: Text(
                        user?.fullName ?? user?.username ?? 'Unknown User',
                      ),
                      subtitle: Text(
                        'Read at ${_formatTime(receipt.readAt)}',
                        style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                      ),
                    );
                  },
                );
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Close'),
          ),
        ],
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
