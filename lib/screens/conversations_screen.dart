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
      context.read<ChatProvider>().initialize();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(AppStrings.conversations),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
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
            onPressed: () => _showCreateConversationDialog(context),
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
                    },
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (chatProvider.conversations.isEmpty) {
            return RefreshIndicator(
              onRefresh: () async {
                await chatProvider.refreshConversations();
              },
              child: const Center(child: Text(AppStrings.noConversations)),
            );
          }

          return RefreshIndicator(
            onRefresh: () async {
              await chatProvider.refreshConversations();
            },
            child: ListView.builder(
              itemCount: chatProvider.conversations.length,
              itemBuilder: (context, index) {
                final conversation = chatProvider.conversations[index];
                return _buildConversationItem(context, conversation);
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
                      style: const TextStyle(fontWeight: FontWeight.w500),
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
                      style: const TextStyle(color: Colors.grey),
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
                children: [
                  Text(
                    Utils.formatDate(conversation.lastActivity),
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  if (conversation.isActive)
                    const Icon(Icons.circle, color: Colors.blue, size: 8),
                ],
              ),
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) =>
                        ChatScreen(conversation: conversation),
                  ),
                );
              },
            ),
          );
        },
      );
    } else {
      // Group conversation
      return Card(
        margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
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
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          subtitle: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              if (conversation.lastMessage != null)
                Text(
                  conversation.lastMessage!,
                  style: const TextStyle(color: Colors.grey),
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
            children: [
              Text(
                Utils.formatDate(conversation.lastActivity),
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              const SizedBox(height: 4),
              if (conversation.isActive)
                const Icon(Icons.circle, color: Colors.blue, size: 8),
            ],
          ),
          onTap: () {
            Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => ChatScreen(conversation: conversation),
              ),
            );
          },
        ),
      );
    }
  }

  void _showCreateConversationDialog(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => const CreateConversationDialog(),
    );
  }
}

class CreateConversationDialog extends StatefulWidget {
  const CreateConversationDialog({super.key});

  @override
  State<CreateConversationDialog> createState() =>
      _CreateConversationDialogState();
}

class _CreateConversationDialogState extends State<CreateConversationDialog> {
  final _titleController = TextEditingController();
  final _participantController = TextEditingController();
  String _selectedType = ApiConstants.conversationTypeDirect;
  final List<String> _participants = [];

  @override
  void dispose() {
    _titleController.dispose();
    _participantController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text(AppStrings.createConversation),
      content: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          DropdownButtonFormField<String>(
            value: _selectedType,
            decoration: const InputDecoration(labelText: 'Type'),
            items: const [
              DropdownMenuItem(
                value: ApiConstants.conversationTypeDirect,
                child: Text('Direct'),
              ),
              DropdownMenuItem(
                value: ApiConstants.conversationTypeGroup,
                child: Text('Group'),
              ),
            ],
            onChanged: (value) {
              setState(() {
                _selectedType = value!;
              });
            },
          ),
          const SizedBox(height: 16),

          if (_selectedType == ApiConstants.conversationTypeGroup)
            TextField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: 'Group Title'),
            ),

          const SizedBox(height: 16),
          TextField(
            controller: _participantController,
            decoration: const InputDecoration(
              labelText: 'Participant ID',
              hintText: 'Enter user ID and press Add',
            ),
          ),
          const SizedBox(height: 8),

          ElevatedButton(
            onPressed: () {
              final participantId = _participantController.text.trim();
              if (participantId.isNotEmpty &&
                  !_participants.contains(participantId)) {
                setState(() {
                  _participants.add(participantId);
                  _participantController.clear();
                });
              }
            },
            child: const Text('Add Participant'),
          ),

          if (_participants.isNotEmpty) ...[
            const SizedBox(height: 16),
            const Text('Participants:'),
            ..._participants.map(
              (id) => Chip(
                label: Text(id),
                onDeleted: () {
                  setState(() {
                    _participants.remove(id);
                  });
                },
              ),
            ),
          ],
        ],
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('Cancel'),
        ),
        ElevatedButton(
          onPressed: _participants.isNotEmpty ? _createConversation : null,
          child: const Text('Create'),
        ),
      ],
    );
  }

  Future<void> _createConversation() async {
    try {
      await context.read<ChatProvider>().createConversation(
        type: _selectedType,
        participants: _participants,
        title: _titleController.text.trim().isNotEmpty
            ? _titleController.text.trim()
            : null,
      );

      if (mounted) {
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error creating conversation: $e')),
        );
      }
    }
  }
}
