import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import '../bloc/bloc.dart';
import '../models/conversation.dart';
import '../widgets/user_avatar.dart';
import 'chat_screen_bloc.dart';

class ConversationListScreenBloc extends StatefulWidget {
  const ConversationListScreenBloc({super.key});

  @override
  State<ConversationListScreenBloc> createState() =>
      _ConversationListScreenBlocState();
}

class _ConversationListScreenBlocState
    extends State<ConversationListScreenBloc> {
  @override
  void initState() {
    super.initState();
    // Load conversations when screen opens
    context.read<ConversationBloc>().add(LoadConversations());
  }

  void _refreshConversations() {
    context.read<ConversationBloc>().add(RefreshConversations());
  }

  void _openChat(Conversation conversation) {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => MultiBlocProvider(
          providers: [
            BlocProvider.value(value: context.read<MessageBloc>()),
            BlocProvider.value(value: context.read<ConversationBloc>()),
          ],
          child: ChatScreenBloc(conversation: conversation),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Conversations'),
        actions: [
          BlocBuilder<ConversationBloc, ConversationState>(
            builder: (context, state) {
              if (state is ConversationLoaded) {
                final unreadCount = state.getTotalUnreadCount();
                if (unreadCount > 0) {
                  return Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 4,
                      ),
                      decoration: BoxDecoration(
                        color: Colors.red,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '$unreadCount',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  );
                }
              }
              return const SizedBox();
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _refreshConversations,
          ),
        ],
      ),
      body: BlocConsumer<ConversationBloc, ConversationState>(
        listener: (context, state) {
          if (state is ConversationError) {
            ScaffoldMessenger.of(
              context,
            ).showSnackBar(SnackBar(content: Text(state.error)));
          }
        },
        builder: (context, state) {
          if (state is ConversationLoading) {
            return const Center(child: CircularProgressIndicator());
          } else if (state is ConversationError) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Error: ${state.error}'),
                  ElevatedButton(
                    onPressed: _refreshConversations,
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          } else if (state is ConversationLoaded) {
            final conversations = state.getActiveConversations();

            if (conversations.isEmpty) {
              return const Center(
                child: Text('No conversations yet. Start a new chat!'),
              );
            }

            return RefreshIndicator(
              onRefresh: () async {
                _refreshConversations();
              },
              child: ListView.builder(
                itemCount: conversations.length,
                itemBuilder: (context, index) {
                  final conversation = conversations[index];
                  return _buildConversationTile(conversation);
                },
              ),
            );
          }

          return const Center(child: Text('Loading conversations...'));
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () {
          // Navigate to create conversation screen
          _showCreateConversationDialog();
        },
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildConversationTile(Conversation conversation) {
    return Dismissible(
      key: Key(conversation.id),
      background: Container(
        color: Colors.orange,
        alignment: Alignment.centerLeft,
        padding: const EdgeInsets.only(left: 20),
        child: const Icon(Icons.volume_off, color: Colors.white),
      ),
      secondaryBackground: Container(
        color: Colors.red,
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: const Icon(Icons.archive, color: Colors.white),
      ),
      confirmDismiss: (direction) async {
        if (direction == DismissDirection.startToEnd) {
          // Mute conversation
          context.read<ConversationBloc>().add(
            MuteConversation(conversation.id, !conversation.isMuted),
          );
          return false;
        } else if (direction == DismissDirection.endToStart) {
          // Archive conversation
          context.read<ConversationBloc>().add(
            ArchiveConversation(conversation.id, true),
          );
          return true;
        }
        return false;
      },
      child: ListTile(
        leading: UserAvatar(
          displayName: conversation.title ?? 'Chat',
          size: 50,
          showOnlineIndicator: true,
          isOnline: conversation.isActive,
        ),
        title: Text(
          conversation.title ?? 'Direct Message',
          style: TextStyle(
            fontWeight: conversation.unreadCount > 0
                ? FontWeight.bold
                : FontWeight.normal,
          ),
        ),
        subtitle: Text(
          conversation.lastMessage ?? 'No messages',
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: TextStyle(
            color: conversation.unreadCount > 0
                ? Colors.black87
                : Colors.grey[600],
            fontWeight: conversation.unreadCount > 0
                ? FontWeight.w500
                : FontWeight.normal,
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(
              _formatTime(conversation.lastActivity),
              style: TextStyle(
                fontSize: 12,
                color: conversation.unreadCount > 0
                    ? Colors.blue
                    : Colors.grey[600],
              ),
            ),
            if (conversation.unreadCount > 0) ...[
              const SizedBox(height: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Text(
                  '${conversation.unreadCount}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
            if (conversation.isMuted) ...[
              const SizedBox(height: 2),
              const Icon(Icons.volume_off, size: 16, color: Colors.grey),
            ],
          ],
        ),
        onTap: () => _openChat(conversation),
        onLongPress: () => _showConversationOptions(conversation),
      ),
    );
  }

  void _showConversationOptions(Conversation conversation) {
    showModalBottomSheet(
      context: context,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(
                conversation.isMuted ? Icons.volume_up : Icons.volume_off,
              ),
              title: Text(conversation.isMuted ? 'Unmute' : 'Mute'),
              onTap: () {
                Navigator.pop(context);
                context.read<ConversationBloc>().add(
                  MuteConversation(conversation.id, !conversation.isMuted),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.archive),
              title: const Text('Archive'),
              onTap: () {
                Navigator.pop(context);
                context.read<ConversationBloc>().add(
                  ArchiveConversation(conversation.id, true),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.mark_email_read),
              title: const Text('Mark as Read'),
              onTap: () {
                Navigator.pop(context);
                context.read<ConversationBloc>().add(
                  MarkConversationAsRead(conversation.id),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  void _showCreateConversationDialog() {
    final titleController = TextEditingController();

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('New Conversation'),
        content: TextField(
          controller: titleController,
          decoration: const InputDecoration(
            labelText: 'Conversation Title',
            hintText: 'Enter title...',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () {
              final title = titleController.text.trim();
              if (title.isNotEmpty) {
                context.read<ConversationBloc>().add(
                  CreateConversation(
                    type: 'group',
                    participants: [
                      'current_user_id',
                    ], // Replace with actual participants
                    title: title,
                  ),
                );
                Navigator.pop(context);
              }
            },
            child: const Text('Create'),
          ),
        ],
      ),
    );
  }

  String _formatTime(DateTime dateTime) {
    final now = DateTime.now();
    final difference = now.difference(dateTime);

    if (difference.inDays > 0) {
      return '${difference.inDays}d';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m';
    } else {
      return 'Now';
    }
  }
}
