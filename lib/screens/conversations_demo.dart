import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../widgets/realtime_conversation_list.dart';

class ConversationsDemo extends StatefulWidget {
  const ConversationsDemo({Key? key}) : super(key: key);

  @override
  State<ConversationsDemo> createState() => _ConversationsDemoState();
}

class _ConversationsDemoState extends State<ConversationsDemo>
    with TickerProviderStateMixin, WidgetsBindingObserver {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
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
    _tabController.dispose();
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
                const Text('Conversations'),
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
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: () {
              context.read<ChatProvider>().requestConversationListRefresh();
            },
          ),
          PopupMenuButton<String>(
            onSelected: (value) {
              switch (value) {
                case 'mark_all_read':
                  _markAllAsRead();
                  break;
                case 'show_stats':
                  _showStats();
                  break;
              }
            },
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'mark_all_read',
                child: Text('Mark all as read'),
              ),
              const PopupMenuItem(
                value: 'show_stats',
                child: Text('Show statistics'),
              ),
            ],
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white70,
          indicatorColor: Colors.white,
          tabs: [
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final activeCount = chatProvider
                    .getActiveConversations()
                    .length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Active'),
                      if (activeCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            activeCount.toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final archivedCount = chatProvider
                    .getArchivedConversations()
                    .length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Archived'),
                      if (archivedCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            archivedCount.toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
            Consumer<ChatProvider>(
              builder: (context, chatProvider, child) {
                final mutedCount = chatProvider.getMutedConversations().length;
                return Tab(
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text('Muted'),
                      if (mutedCount > 0) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.white24,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            mutedCount.toString(),
                            style: const TextStyle(fontSize: 10),
                          ),
                        ),
                      ],
                    ],
                  ),
                );
              },
            ),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Active conversations
          const RealtimeConversationList(showArchived: false),

          // Archived conversations
          const RealtimeConversationList(showArchived: true),

          // Muted conversations
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              final mutedConversations = chatProvider.getMutedConversations();

              if (mutedConversations.isEmpty) {
                return const Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.volume_off, size: 64, color: Colors.grey),
                      SizedBox(height: 16),
                      Text(
                        'No muted conversations',
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                    ],
                  ),
                );
              }

              return ListView.builder(
                itemCount: mutedConversations.length,
                itemBuilder: (context, index) {
                  final conversation = mutedConversations[index];
                  return Card(
                    margin: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    child: ListTile(
                      leading: const CircleAvatar(
                        backgroundColor: Colors.grey,
                        child: Icon(Icons.volume_off, color: Colors.white),
                      ),
                      title: Text(conversation.title ?? 'Unknown'),
                      subtitle: Text(conversation.lastMessage ?? 'No messages'),
                      trailing: IconButton(
                        icon: const Icon(Icons.volume_up),
                        onPressed: () {
                          chatProvider.muteConversation(conversation.id, false);
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Conversation unmuted'),
                            ),
                          );
                        },
                      ),
                    ),
                  );
                },
              );
            },
          ),
        ],
      ),
      bottomNavigationBar: Consumer<ChatProvider>(
        builder: (context, chatProvider, child) {
          return Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border(top: BorderSide(color: Colors.grey[300]!)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                // Connection status
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      chatProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                      color: chatProvider.isConnected
                          ? Colors.green
                          : Colors.red,
                      size: 16,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      chatProvider.isConnected ? 'Connected' : 'Disconnected',
                      style: TextStyle(
                        color: chatProvider.isConnected
                            ? Colors.green
                            : Colors.red,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),

                // Total conversations
                Text(
                  '${chatProvider.conversations.length} conversations',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),

                // Unread count
                if (chatProvider.getTotalUnreadCount() > 0)
                  Text(
                    '${chatProvider.getTotalUnreadCount()} unread',
                    style: const TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
              ],
            ),
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showDebugInfo(),
        icon: const Icon(Icons.bug_report),
        label: const Text('Debug'),
        backgroundColor: Colors.orange,
      ),
    );
  }

  void _markAllAsRead() {
    final chatProvider = context.read<ChatProvider>();
    final unreadConversations = chatProvider.getUnreadConversations();

    for (final conversation in unreadConversations) {
      chatProvider.markConversationAsRead(conversation.id);
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Marked ${unreadConversations.length} conversations as read',
        ),
      ),
    );
  }

  void _showStats() {
    final chatProvider = context.read<ChatProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Conversation Statistics'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Total conversations: ${chatProvider.conversations.length}'),
            Text(
              'Active conversations: ${chatProvider.getActiveConversations().length}',
            ),
            Text(
              'Archived conversations: ${chatProvider.getArchivedConversations().length}',
            ),
            Text(
              'Muted conversations: ${chatProvider.getMutedConversations().length}',
            ),
            Text(
              'Unread conversations: ${chatProvider.getUnreadConversations().length}',
            ),
            Text(
              'Total unread messages: ${chatProvider.getTotalUnreadCount()}',
            ),
            const SizedBox(height: 8),
            Text(
              'WebSocket connected: ${chatProvider.isConnected ? "Yes" : "No"}',
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }

  void _showDebugInfo() {
    final chatProvider = context.read<ChatProvider>();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Debug Information'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Real-time Features:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text(
                '✓ WebSocket connection: ${chatProvider.isConnected ? "Active" : "Inactive"}',
              ),
              Text(
                '✓ Real-time unread count: ${chatProvider.getTotalUnreadCount()}',
              ),
              Text('✓ Auto conversation sorting: Enabled'),
              Text('✓ Conversation list subscriptions: Active'),
              Text('✓ App lifecycle management: Active'),
              const SizedBox(height: 16),

              const Text(
                'Available Actions:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• Long press conversation for options'),
              const Text('• Pull to refresh conversation list'),
              const Text('• Tap conversation to mark as read'),
              const Text('• Use tabs to view different conversation types'),
              const SizedBox(height: 16),

              const Text(
                'WebSocket Events:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              const Text('• message - New messages'),
              const Text('• conversation_list_updated - List changes'),
              const Text('• conversation_read_status_changed - Read status'),
              const Text('• conversation_muted - Mute status'),
              const Text('• conversation_archived - Archive status'),
              const Text('• unread_count_updated - Unread counts'),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () {
              chatProvider.requestConversationListRefresh();
              Navigator.pop(context);
            },
            child: const Text('Refresh'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Close'),
          ),
        ],
      ),
    );
  }
}
