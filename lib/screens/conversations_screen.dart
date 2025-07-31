import 'package:flutter/material.dart';
import 'package:mercury_test/models/user.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';
import '../widgets/premium_status_widget.dart';
import 'chat_screen.dart';
import 'create_conversation_screen.dart';

class ConversationsScreen extends StatefulWidget {
  const ConversationsScreen({super.key});

  @override
  State<ConversationsScreen> createState() => _ConversationsScreenState();
}

class _ConversationsScreenState extends State<ConversationsScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.initialize();
      chatProvider.subscribeToConversationListUpdates();
    });
  }

  @override
  void dispose() {
    context.read<ChatProvider>().unsubscribeFromConversationListUpdates();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      AppStrings.conversations,
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.refresh_rounded),
                    onPressed: () {
                      context
                          .read<ChatProvider>()
                          .requestConversationListRefresh();
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Colors.grey.shade100,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: const Icon(Icons.add_rounded),
                    onPressed: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) =>
                              const CreateConversationScreen(),
                        ),
                      );
                    },
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(context).primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Content
            Expanded(
              child: Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  if (chatProvider.isLoading) {
                    return const Center(child: CircularProgressIndicator());
                  }

                  if (chatProvider.error != null) {
                    return Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.error_outline_rounded,
                            size: 64,
                            color: Colors.grey.shade400,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Something went wrong',
                            style: Theme.of(context).textTheme.titleLarge
                                ?.copyWith(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            chatProvider.error!,
                            style: TextStyle(color: Colors.grey.shade600),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 24),
                          FilledButton.icon(
                            onPressed: () {
                              chatProvider.clearError();
                              chatProvider.initialize();
                              chatProvider.subscribeToConversationListUpdates();
                            },
                            icon: const Icon(Icons.refresh_rounded),
                            label: const Text('Try Again'),
                          ),
                        ],
                      ),
                    );
                  }

                  // Get active conversations (not archived)
                  final activeConversations = chatProvider
                      .getActiveConversations();

                  if (activeConversations.isEmpty) {
                    return RefreshIndicator(
                      onRefresh: () async {
                        await chatProvider.refreshConversations();
                      },
                      child: SingleChildScrollView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        child: SizedBox(
                          height: MediaQuery.of(context).size.height * 0.6,
                          child: Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.chat_bubble_outline_rounded,
                                  size: 64,
                                  color: Colors.grey.shade400,
                                ),
                                const SizedBox(height: 16),
                                Text(
                                  'No conversations yet',
                                  style: Theme.of(context).textTheme.titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w600),
                                ),
                                const SizedBox(height: 8),
                                Text(
                                  'Start a conversation with your friends',
                                  style: TextStyle(color: Colors.grey.shade600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    );
                  }

                  return RefreshIndicator(
                    onRefresh: () async {
                      await chatProvider.refreshConversations();
                      chatProvider.requestConversationListRefresh();
                    },
                    child: ListView.builder(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      itemCount:
                          activeConversations.length +
                          1, // +1 for premium widget
                      itemBuilder: (context, index) {
                        if (index == 0) {
                          return const PremiumStatusWidget(showFullCard: false);
                        }

                        final conversation = activeConversations[index - 1];
                        return _buildConversationItem(context, conversation);
                      },
                    ),
                  );
                },
              ),
            ),
            // Connection status
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                return Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 24,
                    vertical: 8,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        chatProvider.isConnected
                            ? Icons.wifi_rounded
                            : Icons.wifi_off_rounded,
                        color: chatProvider.isConnected
                            ? Colors.green
                            : Colors.orange,
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        chatProvider.isConnected
                            ? 'Connected'
                            : 'Reconnecting...',
                        style: TextStyle(
                          color: chatProvider.isConnected
                              ? Colors.green
                              : Colors.orange,
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conversation,
  ) {
    final chatProvider = context.read<ChatProvider>();

    if (conversation.type == ApiConstants.conversationTypeDirect) {
      // Get the other participant's ID
      final otherParticipantId = chatProvider.getOtherParticipant(conversation);

      return FutureBuilder<User?>(
        future: chatProvider.getUser(otherParticipantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Card(
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey.shade300,
                  child: const CircularProgressIndicator(strokeWidth: 2),
                ),
                title: const Text('Loading...'),
                subtitle: const Text(''),
              ),
            );
          }

          final user = snapshot.data;
          final displayName = user?.fullName?.isNotEmpty == true
              ? user!.fullName!
              : user?.username ?? 'Unknown User';

          return Card(
            child: ListTile(
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              leading: Stack(
                children: [
                  Utils.buildUserAvatar(
                    userId: otherParticipantId,
                    avatarUrl: user?.avatar,
                    displayName: displayName,
                    radius: 28,
                  ),
                  // Online indicator
                  if (user?.isOnline == true)
                    Positioned(
                      right: 2,
                      bottom: 2,
                      child: Container(
                        width: 14,
                        height: 14,
                        decoration: BoxDecoration(
                          color: Colors.green,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 2),
                        ),
                      ),
                    ),
                ],
              ),
              title: Row(
                children: [
                  Expanded(
                    child: Text(
                      displayName,
                      style: const TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  Text(
                    Utils.formatDate(conversation.lastActivity),
                    style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                  ),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 4),
                  if (conversation.lastMessage != null)
                    Text(
                      conversation.lastMessage!,
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontSize: 14,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    Text(
                      'No messages yet',
                      style: TextStyle(
                        color: Colors.grey.shade500,
                        fontSize: 14,
                      ),
                    ),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      if (user?.isOnline == true)
                        const Text(
                          'Online',
                          style: TextStyle(color: Colors.green, fontSize: 12),
                        )
                      else if (user?.lastSeen != null)
                        Text(
                          'Last seen ${Utils.formatTime(user!.lastSeen!)}',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        )
                      else
                        Text(
                          'Offline',
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      const Spacer(),
                      // Indicators
                      Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          // Muted indicator
                          if (conversation.isMuted)
                            Icon(
                              Icons.volume_off_rounded,
                              size: 16,
                              color: Colors.grey.shade500,
                            ),
                          if (conversation.isMuted &&
                              conversation.unreadCount > 0)
                            const SizedBox(width: 4),
                          // Unread count badge
                          if (conversation.unreadCount > 0)
                            Container(
                              padding: const EdgeInsets.symmetric(
                                horizontal: 8,
                                vertical: 4,
                              ),
                              decoration: BoxDecoration(
                                color: conversation.isMuted
                                    ? Colors.grey.shade400
                                    : Theme.of(context).primaryColor,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: Text(
                                conversation.unreadCount > 99
                                    ? '99+'
                                    : conversation.unreadCount.toString(),
                                style: const TextStyle(
                                  color: Colors.white,
                                  fontSize: 11,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
              onTap: () {
                // Mark conversation as read when tapped
                if (conversation.unreadCount > 0) {
                  chatProvider.markConversationAsRead(conversation.id);
                }

                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(conversation: conversation),
                  ),
                );
              },
              onLongPress: () {
                _showConversationOptions(context, conversation, chatProvider);
              },
            ),
          );
        },
      );
    } else {
      // Group conversation
      return Card(
        child: ListTile(
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 16,
            vertical: 8,
          ),
          leading: CircleAvatar(
            backgroundColor: Theme.of(context).primaryColor,
            radius: 28,
            child: Text(
              conversation.title?.isNotEmpty == true
                  ? conversation.title![0].toUpperCase()
                  : 'G',
              style: const TextStyle(
                color: Colors.white,
                fontSize: 18,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  conversation.title ?? AppStrings.groupChat,
                  style: const TextStyle(
                    fontWeight: FontWeight.w600,
                    fontSize: 16,
                  ),
                ),
              ),
              Text(
                Utils.formatDate(conversation.lastActivity),
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
              ),
            ],
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 4),
              if (conversation.lastMessage != null)
                Text(
                  conversation.lastMessage!,
                  style: TextStyle(color: Colors.grey.shade700, fontSize: 14),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
                ),
              const SizedBox(height: 4),
              Row(
                children: [
                  Text(
                    '${conversation.participants.length} members',
                    style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                  ),
                  const Spacer(),
                  // Indicators
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Muted indicator
                      if (conversation.isMuted)
                        Icon(
                          Icons.volume_off_rounded,
                          size: 16,
                          color: Colors.grey.shade500,
                        ),
                      if (conversation.isMuted && conversation.unreadCount > 0)
                        const SizedBox(width: 4),
                      // Unread count badge
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: conversation.isMuted
                                ? Colors.grey.shade400
                                : Theme.of(context).primaryColor,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                    ],
                  ),
                ],
              ),
            ],
          ),
          onTap: () {
            // Mark conversation as read when tapped
            if (conversation.unreadCount > 0) {
              chatProvider.markConversationAsRead(conversation.id);
            }

            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(conversation: conversation),
              ),
            );
          },
          onLongPress: () {
            _showConversationOptions(context, conversation, chatProvider);
          },
        ),
      );
    }
  }

  void _showConversationOptions(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Container(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Conversation Options',
              style: Theme.of(
                context,
              ).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w600),
            ),
            const SizedBox(height: 20),

            // Mark as read/unread
            if (conversation.unreadCount > 0)
              ListTile(
                leading: Icon(
                  Icons.mark_chat_read_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Mark as read'),
                onTap: () {
                  chatProvider.markConversationAsRead(conversation.id);
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              )
            else
              ListTile(
                leading: Icon(
                  Icons.mark_chat_unread_rounded,
                  color: Theme.of(context).primaryColor,
                ),
                title: const Text('Mark as unread'),
                onTap: () {
                  // Mark as unread functionality (if needed)
                  Navigator.pop(context);
                },
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),

            // Mute/Unmute
            ListTile(
              leading: Icon(
                conversation.isMuted
                    ? Icons.volume_up_rounded
                    : Icons.volume_off_rounded,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                chatProvider.muteConversation(
                  conversation.id,
                  !conversation.isMuted,
                );
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            // Archive/Unarchive
            ListTile(
              leading: Icon(
                conversation.isArchived
                    ? Icons.unarchive_rounded
                    : Icons.archive_rounded,
                color: Theme.of(context).primaryColor,
              ),
              title: Text(conversation.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                chatProvider.archiveConversation(
                  conversation.id,
                  !conversation.isArchived,
                );
                Navigator.pop(context);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            // Delete conversation
            ListTile(
              leading: const Icon(Icons.delete_rounded, color: Colors.red),
              title: const Text(
                'Delete conversation',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, conversation, chatProvider);
              },
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),

            const SizedBox(height: 20),
          ],
        ),
      ),
    );
  }

  void _showDeleteConfirmation(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              chatProvider.removeConversationFromList(conversation.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: const Text('Conversation deleted'),
                  behavior: SnackBarBehavior.floating,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              );
            },
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
