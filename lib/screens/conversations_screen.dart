import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';
import 'chat_screen.dart';
import 'profile_screen.dart';

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
            return const Center(child: Text(AppStrings.noConversations));
          }

          return ListView.builder(
            itemCount: chatProvider.conversations.length,
            itemBuilder: (context, index) {
              final conversation = chatProvider.conversations[index];
              return _buildConversationItem(context, conversation);
            },
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
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: Colors.blue,
          child: Text(
            conversation.title?.isNotEmpty == true
                ? conversation.title![0].toUpperCase()
                : conversation.type == 'DIRECT'
                ? 'D'
                : 'G',
            style: const TextStyle(color: Colors.white),
          ),
        ),
        title: Text(
          conversation.title ??
              (conversation.type == ApiConstants.conversationTypeDirect
                  ? AppStrings.directChat
                  : AppStrings.groupChat),
          style: const TextStyle(fontWeight: FontWeight.w500),
        ),
        subtitle: Text(
          conversation.type == ApiConstants.conversationTypeDirect
              ? 'Direct message'
              : '${conversation.participants.length} members',
          style: const TextStyle(color: Colors.grey),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              Utils.formatDate(conversation.lastActivity),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (conversation.isActive)
              const Icon(Icons.circle, color: Colors.green, size: 8),
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
