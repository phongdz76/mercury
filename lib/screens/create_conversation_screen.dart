import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../providers/friend_provider.dart';
import '../models/friend_user.dart';
import '../constants/app_constants.dart';

class CreateConversationScreen extends StatefulWidget {
  const CreateConversationScreen({super.key});

  @override
  State<CreateConversationScreen> createState() =>
      _CreateConversationScreenState();
}

class _CreateConversationScreenState extends State<CreateConversationScreen> {
  final _titleController = TextEditingController();
  final List<String> _selectedFriends = [];
  bool _isCreating = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<FriendProvider>().loadFriends();
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('New Conversation'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          TextButton(
            onPressed: _selectedFriends.isNotEmpty && !_isCreating
                ? _createConversation
                : null,
            child: Text(
              'Create',
              style: TextStyle(
                color: _selectedFriends.isNotEmpty && !_isCreating
                    ? Colors.white
                    : Colors.white54,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      body: Column(
        children: [
          // Group title input (only show if more than 1 friend selected)
          if (_selectedFriends.length > 1)
            Container(
              padding: const EdgeInsets.all(16),
              child: TextField(
                controller: _titleController,
                decoration: const InputDecoration(
                  labelText: 'Group Title (Optional)',
                  hintText: 'Enter group name',
                  border: OutlineInputBorder(),
                ),
              ),
            ),

          // Selected friends summary
          if (_selectedFriends.isNotEmpty)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selectedFriends.length == 1
                        ? 'Selected Friend (1)'
                        : 'Selected Friends (${_selectedFriends.length})',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    _selectedFriends.length == 1
                        ? 'This will create a direct conversation'
                        : 'This will create a group conversation',
                    style: TextStyle(color: Colors.grey[600], fontSize: 14),
                  ),
                ],
              ),
            ),

          const Divider(),

          // Friends list
          Expanded(
            child: Consumer<FriendProvider>(
              builder: (context, friendProvider, child) {
                if (friendProvider.loading) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (friendProvider.error != null) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Error: ${friendProvider.error}'),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: () => friendProvider.loadFriends(),
                          child: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                if (friendProvider.friends.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.people_outline,
                          size: 64,
                          color: Colors.grey,
                        ),
                        SizedBox(height: 16),
                        Text(
                          'No friends yet',
                          style: TextStyle(fontSize: 18, color: Colors.grey),
                        ),
                        SizedBox(height: 8),
                        Text(
                          'Add friends to start conversations',
                          style: TextStyle(color: Colors.grey),
                        ),
                      ],
                    ),
                  );
                }

                return ListView.builder(
                  itemCount: friendProvider.friends.length,
                  itemBuilder: (context, index) {
                    final friend = friendProvider.friends[index];
                    return _buildFriendTile(friend);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFriendTile(FriendUser friend) {
    final isSelected = _selectedFriends.contains(friend.id);

    return ListTile(
      leading: Stack(
        children: [
          CircleAvatar(
            backgroundImage: friend.avatar != null
                ? NetworkImage(friend.avatar!)
                : null,
            child: friend.avatar == null
                ? Text(friend.username[0].toUpperCase())
                : null,
          ),
          // Online indicator
          if (friend.isOnline)
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
      title: Text(friend.username),
      subtitle: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(friend.fullName ?? friend.email),
          if (friend.isOnline)
            const Text(
              'Online',
              style: TextStyle(color: Colors.green, fontSize: 12),
            )
          else if (friend.lastSeen != null)
            Text(
              'Last seen ${_formatLastSeen(friend.lastSeen!)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
        ],
      ),
      trailing: Checkbox(
        value: isSelected,
        onChanged: (bool? value) {
          setState(() {
            if (value == true) {
              _selectedFriends.add(friend.id);
            } else {
              _selectedFriends.remove(friend.id);
            }
          });
        },
      ),
      onTap: () {
        setState(() {
          if (isSelected) {
            _selectedFriends.remove(friend.id);
          } else {
            _selectedFriends.add(friend.id);
          }
        });
      },
    );
  }

  String _formatLastSeen(DateTime lastSeen) {
    final now = DateTime.now();
    final difference = now.difference(lastSeen);

    if (difference.inMinutes < 1) {
      return 'Just now';
    } else if (difference.inMinutes < 60) {
      return '${difference.inMinutes}m ago';
    } else if (difference.inHours < 24) {
      return '${difference.inHours}h ago';
    } else if (difference.inDays < 7) {
      return '${difference.inDays}d ago';
    } else {
      return '${lastSeen.day}/${lastSeen.month}/${lastSeen.year}';
    }
  }

  Future<void> _createConversation() async {
    if (_selectedFriends.isEmpty) return;

    setState(() {
      _isCreating = true;
    });

    try {
      final chatProvider = context.read<ChatProvider>();

      // Determine conversation type based on number of participants
      final String type = _selectedFriends.length == 1
          ? ApiConstants.conversationTypeDirect
          : ApiConstants.conversationTypeGroup;

      // Use title only for group conversations
      String? title;
      if (_selectedFriends.length > 1) {
        final titleText = _titleController.text.trim();
        title = titleText.isNotEmpty ? titleText : null;
      }

      // Use createOrGetConversation for better handling
      await chatProvider.createOrGetConversation(
        type: type,
        participants: _selectedFriends,
        title: title,
      );

      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              _selectedFriends.length == 1
                  ? 'Conversation ready'
                  : 'Group conversation ready',
            ),
            backgroundColor: Colors.green,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        String errorMessage = 'Error creating conversation: $e';

        // Handle specific error cases
        if (e.toString().contains('Conversation already exists')) {
          errorMessage = 'You already have a conversation with this friend';
        } else if (e.toString().contains(
          'Group conversation with same participants',
        )) {
          errorMessage =
              'A group conversation with these friends already exists';
        }

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(errorMessage), backgroundColor: Colors.orange),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isCreating = false;
        });
      }
    }
  }
}
