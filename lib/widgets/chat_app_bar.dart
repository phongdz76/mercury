import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';
import '../widgets/user_avatar.dart';

class ChatAppBar extends StatelessWidget implements PreferredSizeWidget {
  final Conversation conversation;

  const ChatAppBar({super.key, required this.conversation});

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);

  @override
  Widget build(BuildContext context) {
    return AppBar(
      title: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          // For direct chat, show the other participant's name and avatar
          if (conversation.type == ApiConstants.conversationTypeDirect) {
            final otherParticipantId = chatProvider.getOtherParticipant(
              conversation,
            );
            final otherParticipantName = chatProvider.getUserDisplayName(
              otherParticipantId,
            );
            final otherParticipantAvatar = chatProvider.getUserAvatar(
              otherParticipantId,
            );
            final otherUser = chatProvider.userCache[otherParticipantId];

            return Row(
              children: [
                UserAvatar(
                  avatarUrl: otherParticipantAvatar,
                  displayName: otherParticipantName,
                  size: 36,
                  showOnlineIndicator: true,
                  isOnline: otherUser?.isOnline ?? false,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        otherParticipantName,
                        style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                      if (otherUser != null)
                        Text(
                          otherUser.isOnline
                              ? 'Online'
                              : otherUser.lastSeen != null
                              ? 'Last seen ${Utils.formatRelativeTime(otherUser.lastSeen!)}'
                              : 'Offline',
                          style: const TextStyle(
                            fontSize: 12,
                            color: Colors.white70,
                          ),
                        ),
                    ],
                  ),
                ),
              ],
            );
          } else {
            // For group chat, show the conversation title and member count
            final memberCount = conversation.participants.length;
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  conversation.title ?? AppStrings.groupChat,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                  overflow: TextOverflow.ellipsis,
                ),
                Text(
                  '$memberCount members',
                  style: const TextStyle(fontSize: 12, color: Colors.white70),
                ),
              ],
            );
          }
        },
      ),
      backgroundColor: Colors.blue,
      foregroundColor: Colors.white,
      actions: [
        // Clear reply button (if replying)
        Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            if (!chatProvider.isReplyingTo(conversation.id)) {
              return const SizedBox.shrink();
            }
            return IconButton(
              icon: const Icon(Icons.clear),
              onPressed: () {
                chatProvider.clearReplyToMessage(conversation.id);
              },
              tooltip: 'Clear reply',
            );
          },
        ),

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
    );
  }
}
