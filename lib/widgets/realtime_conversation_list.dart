import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';
import '../screens/chat_screen.dart';
import '../models/user.dart';

/// A widget that displays a real-time conversation list
class RealtimeConversationList extends StatefulWidget {
  final bool showArchived;
  final VoidCallback? onRefresh;

  const RealtimeConversationList({
    Key? key,
    this.showArchived = false,
    this.onRefresh,
  }) : super(key: key);

  @override
  State<RealtimeConversationList> createState() =>
      _RealtimeConversationListState();
}

class _RealtimeConversationListState extends State<RealtimeConversationList>
    with AutomaticKeepAliveClientMixin {
  @override
  bool get wantKeepAlive => true;

  @override
  Widget build(BuildContext context) {
    super.build(context);

    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        if (chatProvider.isLoading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (chatProvider.error != null) {
          return _buildErrorWidget(chatProvider);
        }

        // Get conversations based on filter
        final conversations = widget.showArchived
            ? chatProvider.getArchivedConversations()
            : chatProvider.getActiveConversations();

        if (conversations.isEmpty) {
          return _buildEmptyWidget(chatProvider);
        }

        return RefreshIndicator(
          onRefresh: () async {
            await chatProvider.refreshConversations();
            chatProvider.requestConversationListRefresh();
            widget.onRefresh?.call();
          },
          child: ListView.builder(
            itemCount: conversations.length,
            itemBuilder: (context, index) {
              final conversation = conversations[index];
              return _buildConversationItem(
                context,
                conversation,
                chatProvider,
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildErrorWidget(ChatProvider chatProvider) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 64, color: Colors.grey[400]),
          const SizedBox(height: 16),
          Text(
            'Error: ${chatProvider.error}',
            style: const TextStyle(color: Colors.red),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: () {
              chatProvider.clearError();
              chatProvider.initialize();
              chatProvider.subscribeToConversationListUpdates();
            },
            icon: const Icon(Icons.refresh),
            label: const Text('Retry'),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyWidget(ChatProvider chatProvider) {
    return RefreshIndicator(
      onRefresh: () async {
        await chatProvider.refreshConversations();
        chatProvider.requestConversationListRefresh();
        widget.onRefresh?.call();
      },
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        child: Container(
          height: MediaQuery.of(context).size.height * 0.7,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.showArchived
                    ? Icons.archive_outlined
                    : Icons.chat_bubble_outline,
                size: 64,
                color: Colors.grey[400],
              ),
              const SizedBox(height: 16),
              Text(
                widget.showArchived
                    ? 'No archived conversations'
                    : AppStrings.noConversations,
                style: TextStyle(fontSize: 16, color: Colors.grey[600]),
              ),
              if (!widget.showArchived) ...[
                const SizedBox(height: 8),
                Text(
                  'Start a new conversation with your friends',
                  style: TextStyle(fontSize: 14, color: Colors.grey[500]),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConversationItem(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    final bool hasUnread = conversation.unreadCount > 0;

    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      color: hasUnread ? Colors.blue.withOpacity(0.05) : null,
      elevation: hasUnread ? 2 : 1,
      child: conversation.type == ApiConstants.conversationTypeDirect
          ? _buildDirectConversationTile(context, conversation, chatProvider)
          : _buildGroupConversationTile(context, conversation, chatProvider),
    );
  }

  Widget _buildDirectConversationTile(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    final otherParticipantId = chatProvider.getOtherParticipant(conversation);

    return FutureBuilder<User?>(
      future: chatProvider.getUser(otherParticipantId),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildLoadingTile();
        }

        final user = snapshot.data;
        final displayName = user?.fullName?.isNotEmpty == true
            ? user!.fullName!
            : user?.username ?? 'Unknown User';

        return ListTile(
          leading: _buildUserAvatar(user, displayName, otherParticipantId),
          title: _buildConversationTitle(
            displayName,
            conversation,
            user?.isOnline,
          ),
          subtitle: _buildConversationSubtitle(conversation, user),
          trailing: _buildConversationTrailing(conversation),
          onTap: () => _onConversationTap(context, conversation, chatProvider),
          onLongPress: () =>
              _showConversationOptions(context, conversation, chatProvider),
        );
      },
    );
  }

  Widget _buildGroupConversationTile(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.blue,
        child: Text(
          conversation.title?.isNotEmpty == true
              ? conversation.title![0].toUpperCase()
              : 'G',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: _buildConversationTitle(
        conversation.title ?? AppStrings.groupChat,
        conversation,
        null,
      ),
      subtitle: _buildGroupSubtitle(conversation),
      trailing: _buildConversationTrailing(conversation),
      onTap: () => _onConversationTap(context, conversation, chatProvider),
      onLongPress: () =>
          _showConversationOptions(context, conversation, chatProvider),
    );
  }

  Widget _buildLoadingTile() {
    return ListTile(
      leading: CircleAvatar(
        backgroundColor: Colors.grey[300],
        child: const CircularProgressIndicator(strokeWidth: 2),
      ),
      title: const Text('Loading...'),
      subtitle: const Text(''),
    );
  }

  Widget _buildUserAvatar(User? user, String displayName, String userId) {
    return Stack(
      children: [
        Utils.buildUserAvatar(
          userId: userId,
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
    );
  }

  Widget _buildConversationTitle(
    String title,
    Conversation conversation,
    bool? isOnline,
  ) {
    return Row(
      children: [
        Expanded(
          child: Text(
            title,
            style: TextStyle(
              fontWeight: conversation.unreadCount > 0
                  ? FontWeight.bold
                  : FontWeight.w500,
            ),
            overflow: TextOverflow.ellipsis,
          ),
        ),
        if (isOnline == true)
          const Icon(Icons.circle, color: Colors.green, size: 8),
      ],
    );
  }

  Widget _buildConversationSubtitle(Conversation conversation, User? user) {
    return Column(
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
          const Text('No messages yet', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 2),
        _buildUserStatus(user),
      ],
    );
  }

  Widget _buildGroupSubtitle(Conversation conversation) {
    return Column(
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
          const Text('No messages yet', style: TextStyle(color: Colors.grey)),
        const SizedBox(height: 2),
        Text(
          '${conversation.participants.length} members',
          style: const TextStyle(color: Colors.grey, fontSize: 12),
        ),
      ],
    );
  }

  Widget _buildUserStatus(User? user) {
    if (user?.isOnline == true) {
      return const Text(
        'Online',
        style: TextStyle(color: Colors.green, fontSize: 12),
      );
    } else if (user?.lastSeen != null) {
      return Text(
        'Last seen ${Utils.formatTime(user!.lastSeen!)}',
        style: const TextStyle(color: Colors.grey, fontSize: 12),
      );
    } else {
      return const Text(
        'Offline',
        style: TextStyle(color: Colors.grey, fontSize: 12),
      );
    }
  }

  Widget _buildConversationTrailing(Conversation conversation) {
    return Column(
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
            if (conversation.isMuted && conversation.unreadCount > 0)
              const SizedBox(width: 4),
            // Unread count badge
            if (conversation.unreadCount > 0)
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
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
            else if (conversation.isActive && !conversation.isMuted)
              const Icon(Icons.circle, color: Colors.blue, size: 8),
          ],
        ),
      ],
    );
  }

  void _onConversationTap(
    BuildContext context,
    Conversation conversation,
    ChatProvider chatProvider,
  ) {
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

            // Mark as read
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
                _showSnackBar(
                  context,
                  conversation.isMuted
                      ? 'Conversation unmuted'
                      : 'Conversation muted',
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
                _showSnackBar(
                  context,
                  conversation.isArchived
                      ? 'Conversation unarchived'
                      : 'Conversation archived',
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
              _showSnackBar(context, 'Conversation deleted');
            },
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }

  void _showSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }
}
