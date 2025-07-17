import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/user.dart';

class BlockedUsersScreen extends StatefulWidget {
  const BlockedUsersScreen({Key? key}) : super(key: key);

  @override
  State<BlockedUsersScreen> createState() => _BlockedUsersScreenState();
}

class _BlockedUsersScreenState extends State<BlockedUsersScreen> {
  @override
  void initState() {
    super.initState();
    _loadBlockedUsers();
  }

  Future<void> _loadBlockedUsers() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.loadBlockedUsers();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Blocked Users'),
        backgroundColor: Colors.red,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          if (friendProvider.loading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (friendProvider.error != null) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.error, size: 64, color: Colors.red),
                  const SizedBox(height: 16),
                  Text('Error: ${friendProvider.error}'),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: () => friendProvider.loadBlockedUsers(),
                    child: const Text('Retry'),
                  ),
                ],
              ),
            );
          }

          if (friendProvider.blockedUsers.isEmpty) {
            return const Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.block, size: 64, color: Colors.grey),
                  SizedBox(height: 16),
                  Text('No blocked users'),
                  SizedBox(height: 8),
                  Text('Users you block will appear here'),
                ],
              ),
            );
          }

          return RefreshIndicator(
            onRefresh: () => friendProvider.loadBlockedUsers(),
            child: ListView.builder(
              itemCount: friendProvider.blockedUsers.length,
              itemBuilder: (context, index) {
                final user = friendProvider.blockedUsers[index];
                return _buildBlockedUserTile(user);
              },
            ),
          );
        },
      ),
    );
  }

  Widget _buildBlockedUserTile(User user) {
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: user.avatar != null
              ? NetworkImage(user.avatar!)
              : null,
          child: user.avatar == null
              ? Text(user.username[0].toUpperCase())
              : null,
        ),
        title: Text(user.username),
        subtitle: Text(user.fullName ?? user.email),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Chip(
              label: const Text('Blocked'),
              backgroundColor: Colors.red.withOpacity(0.2),
              labelStyle: const TextStyle(color: Colors.red),
            ),
            const SizedBox(width: 8),
            ElevatedButton(
              onPressed: () => _unblockUser(user),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green,
                foregroundColor: Colors.white,
              ),
              child: const Text('Unblock'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _unblockUser(User user) async {
    final confirmed = await _showConfirmDialog(
      'Unblock User',
      'Are you sure you want to unblock ${user.username}?',
    );

    if (confirmed) {
      final friendProvider = Provider.of<FriendProvider>(
        context,
        listen: false,
      );
      try {
        await friendProvider.unblockUser(user.id);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('${user.username} has been unblocked')),
          );
        }
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(
            context,
          ).showSnackBar(SnackBar(content: Text('Error unblocking user: $e')));
        }
      }
    }
  }

  Future<bool> _showConfirmDialog(String title, String message) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: Text(title),
            content: Text(message),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancel'),
              ),
              TextButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: TextButton.styleFrom(foregroundColor: Colors.green),
                child: const Text('Unblock'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
