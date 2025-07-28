import 'package:flutter/material.dart';
import 'package:mercury_test/models/user.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';
import 'friends_screen.dart';
import 'create_conversation_screen.dart';

class ConversationsScreenEnhanced extends StatefulWidget {
  const ConversationsScreenEnhanced({super.key});

  @override
  State<ConversationsScreenEnhanced> createState() =>
      _ConversationsScreenEnhancedState();
}

class _ConversationsScreenEnhancedState
    extends State<ConversationsScreenEnhanced>
    with WidgetsBindingObserver {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final chatProvider = context.read<ChatProvider>();
      chatProvider.initialize();
      chatProvider.subscribeToConversationListUpdates();
    });
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    context.read<ChatProvider>().unsubscribeFromConversationListUpdates();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final chatProvider = context.read<ChatProvider>();
    switch (state) {
      case AppLifecycleState.resumed:
        chatProvider.subscribeToConversationListUpdates();
        break;
      case AppLifecycleState.paused:
        chatProvider.unsubscribeFromConversationListUpdates();
        break;
      default:
        break;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final unreadCount = chatProvider.getTotalUnreadCount();
            return Row(
              children: [
                const Text(AppStrings.conversations),
                if (unreadCount > 0) ...[
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.red,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      unreadCount.toString(),
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          // Refresh button
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatProvider>().requestConversationListRefresh();
            },
          ),
          IconButton(
            icon: const Icon(Icons.people),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const FriendsScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.person),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const ProfileScreen()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const CreateConversationScreen(),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          if (chatProvider.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (chatProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    'Error: ${chatProvider.error}',
                    style: const TextStyle(color: Colors.red),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () {
                      chatProvider.clearError();
                      chatProvider.initialize();
                      chatProvider.subscribeToConversationListUpdates();
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          // Get active conversations (not archived)
          final activeConversations = chatProvider.getActiveConversations();

          if (activeConversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await chatProvider.refreshConversations();
                chatProvider.requestConversationListRefresh();
              },
              child: SingleChildScrollView(
                physics: const AlwaysScrollableScrollPhysics(),
                child: Container(
                  height: MediaQuery.of(context).size.height * 0.7,
                  child: const Center(child: Text(AppStrings.noConversations)),
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
              itemCount: activeConversations.length,
              itemBuilder: (context, index) {
                final conversation = activeConversations[index];
                return _buildConversationItem(
                  context,
                  conversation,
                  chatProvider,
                );
              },
            ),
          );
        },
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Container(
            padding: const EdgeInsets.all(8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  chatProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                  color: chatProvider.isConnected ? Colors.green : Colors.red,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Text(
                  chatProvider.isConnected ? 'Connected' : 'Disconnected',
                  style: TextStyle(
                    color: chatProvider.isConnected ? Colors.green : Colors.red,
                    fontSize: 12,
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    if (conversation.type == ApiConstants.conversationTypeDirect) {
      // Get the other participant's ID
      final otherParticipantId = chatProvider.getOtherParticipant(conversation);

      return FutureBuilder<User?>(
        future: chatProvider.getUser(otherParticipantId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return Card(
              margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: Colors.grey[300],
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
            margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
            color: conversation.unreadCount > 0
                ? Colors.blue.withOpacity(0.05)
                : null,
            child: ListTile(
              leading: Stack(
                children: [
                  Utils.buildUserAvatar(
                    userId: otherParticipantId,
                    avatarUrl: user?.avatar,
                    displayName: displayName,
                    radius: 24,
                  ),
                  // Online indicator
                  if (user?.isOnline == true)
                    Positioned(
                      right: 0,
                      bottom: 0,
                      child: Container(
                        width: 12,
                        height: 12,
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
                      style: TextStyle(
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.bold
                            : FontWeight.w500,
                      ),
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  if (user?.isOnline == true)
                    const Icon(Icons.circle, color: Colors.green, size: 8),
                ],
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (conversation.lastMessage != null)
                    Text(
                      conversation.lastMessage!,
                      style: TextStyle(
                        color: Colors.grey,
                        fontWeight: conversation.unreadCount > 0
                            ? FontWeight.w500
                            : FontWeight.normal,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    )
                  else
                    const Text(
                      'No messages yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  const SizedBox(height: 2),
                  if (user?.isOnline == true)
                    const Text(
                      'Online',
                      style: TextStyle(color: Colors.green, fontSize: 12),
                    )
                  else if (user?.lastSeen != null)
                    Text(
                      'Last seen ${Utils.formatTime(user!.lastSeen!)}',
                      style: const TextStyle(color: Colors.grey, fontSize: 12),
                    )
                  else
                    const Text(
                      'Offline',
                      style: TextStyle(color: Colors.grey, fontSize: 12),
                    ),
                ],
              ),
              trailing: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    Utils.formatDate(conversation.lastActivity),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Muted indicator
                      if (conversation.isMuted)
                        const Icon(
                          Icons.volume_off,
                          size: 16,
                          color: Colors.grey,
                        ),
                      const SizedBox(width: 4),
                      // Unread count badge
                      if (conversation.unreadCount > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: conversation.isMuted
                                ? Colors.grey
                                : Colors.red,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            conversation.unreadCount > 99
                                ? '99+'
                                : conversation.unreadCount.toString(),
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        )
                      else if (conversation.isActive)
                        const Icon(Icons.circle, color: Colors.blue, size: 8),
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
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        color: conversation.unreadCount > 0
            ? Colors.blue.withOpacity(0.05)
            : null,
        child: ListTile(
          leading: CircleAvatar(
            backgroundColor: Colors.blue,
            child: Text(
              conversation.title?.isNotEmpty == true
                  ? conversation.title![0].toUpperCase()
                  : 'G',
              style: const TextStyle(color: Colors.white),
            ),
          ),
          title: Text(
            conversation.title ?? AppStrings.groupChat,
            style: TextStyle(
              fontWeight: conversation.unreadCount > 0
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conversation.lastMessage != null)
                Text(
                  conversation.lastMessage!,
                  style: TextStyle(
                    color: Colors.grey,
                    fontWeight: conversation.unreadCount > 0
                        ? FontWeight.w500
                        : FontWeight.normal,
                  ),
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                )
              else
                const Text(
                  'No messages yet',
                  style: TextStyle(color: Colors.grey),
                ),
              const SizedBox(height: 2),
              Text(
                '${conversation.participants.length} members',
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              ),
            ],
          ),
          trailing: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                Utils.formatDate(conversation.lastActivity),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Muted indicator
                  if (conversation.isMuted)
                    const Icon(Icons.volume_off, size: 16, color: Colors.grey),
                  const SizedBox(width: 4),
                  // Unread count badge
                  if (conversation.unreadCount > 0)
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 6,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: conversation.isMuted ? Colors.grey : Colors.red,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Text(
                        conversation.unreadCount > 99
                            ? '99+'
                            : conversation.unreadCount.toString(),
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    )
                  else if (conversation.isActive)
                    const Icon(Icons.circle, color: Colors.blue, size: 8),
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
      builder: (context) => Container(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Conversation Options',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),

            // Mark as read/unread
            if (conversation.unreadCount > 0)
              ListTile(
                leading: const Icon(Icons.mark_chat_read),
                title: const Text('Mark as read'),
                onTap: () {
                  chatProvider.markConversationAsRead(conversation.id);
                  Navigator.pop(context);
                },
              ),

            // Mute/Unmute
            ListTile(
              leading: Icon(
                conversation.isMuted ? Icons.volume_up : Icons.volume_off,
              ),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                chatProvider.muteConversation(
                  conversation.id,
                  !conversation.isMuted,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      conversation.isMuted
                          ? 'Conversation unmuted'
                          : 'Conversation muted',
                    ),
                  ),
                );
              },
            ),

            // Archive/Unarchive
            ListTile(
              leading: Icon(
                conversation.isArchived ? Icons.unarchive : Icons.archive,
              ),
              title: Text(conversation.isArchived ? 'Unarchive' : 'Archive'),
              onTap: () {
                chatProvider.archiveConversation(
                  conversation.id,
                  !conversation.isArchived,
                );
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      conversation.isArchived
                          ? 'Conversation unarchived'
                          : 'Conversation archived',
                    ),
                  ),
                );
              },
            ),

            // Delete conversation
            ListTile(
              leading: const Icon(Icons.delete, color: Colors.red),
              title: const Text(
                'Delete conversation',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () {
                Navigator.pop(context);
                _showDeleteConfirmation(context, conversation, chatProvider);
              },
            ),
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
        title: const Text('Delete Conversation'),
        content: const Text(
          'Are you sure you want to delete this conversation? This action cannot be undone.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () {
              chatProvider.removeConversationFromList(conversation.id);
              Navigator.pop(context);
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(content: Text('Conversation deleted')),
              );
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}
