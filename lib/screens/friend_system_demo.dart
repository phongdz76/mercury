import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/friendship.dart';
import '../models/friend_user.dart';

class FriendSystemDemo extends StatefulWidget {
  const FriendSystemDemo({Key? key}) : super(key: key);

  @override
  State<FriendSystemDemo> createState() => _FriendSystemDemoState();
}

class _FriendSystemDemoState extends State<FriendSystemDemo> {
  @override
  void initState() {
    super.initState();
    _loadDemoData();
  }

  Future<void> _loadDemoData() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    try {
      await Future.wait([
        friendProvider.loadFriends(),
        friendProvider.loadPendingRequests(),
        friendProvider.loadSentRequests(),
      ]);
    } catch (e) {
      debugPrint('Error loading demo data: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friend System Demo'),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
      ),
      body: Consumer<FriendProvider>(
        builder: (context, friendProvider, child) {
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildStatusCard(friendProvider),
                const SizedBox(height: 20),
                _buildSearchDemo(friendProvider),
                const SizedBox(height: 20),
                _buildFriendsList(friendProvider),
                const SizedBox(height: 20),
                _buildPendingRequests(friendProvider),
                const SizedBox(height: 20),
                _buildSentRequests(friendProvider),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildStatusCard(FriendProvider friendProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Friend System Status',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                _buildStatusItem(
                  'Friends',
                  friendProvider.friends.length.toString(),
                ),
                _buildStatusItem(
                  'Pending',
                  friendProvider.pendingRequests.length.toString(),
                ),
                _buildStatusItem(
                  'Sent',
                  friendProvider.sentRequests.length.toString(),
                ),
              ],
            ),
            if (friendProvider.loading) ...[
              const SizedBox(height: 12),
              const LinearProgressIndicator(),
            ],
            if (friendProvider.error != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  'Error: ${friendProvider.error}',
                  style: const TextStyle(color: Colors.red),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatusItem(String label, String value) {
    return Column(
      children: [
        Text(
          value,
          style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
        ),
        Text(label),
      ],
    );
  }

  Widget _buildSearchDemo(FriendProvider friendProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Search Users Demo',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            TextField(
              decoration: const InputDecoration(
                labelText: 'Search for users...',
                prefixIcon: Icon(Icons.search),
                border: OutlineInputBorder(),
              ),
              onChanged: (query) {
                if (query.isNotEmpty) {
                  friendProvider.searchUsers(query);
                } else {
                  friendProvider.clearSearchResults();
                }
              },
            ),
            const SizedBox(height: 12),
            if (friendProvider.searchResults.isNotEmpty) ...[
              const Text('Search Results:'),
              const SizedBox(height: 8),
              ...friendProvider.searchResults.map(
                (user) => ListTile(
                  leading: CircleAvatar(
                    child: Text(user.username[0].toUpperCase()),
                  ),
                  title: Text(user.username),
                  subtitle: Text(user.email),
                  trailing: _buildFriendshipStatusChip(user.friendshipStatus),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildFriendsList(FriendProvider friendProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Your Friends',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (friendProvider.friends.isEmpty)
              const Text('No friends yet. Start by searching for users!')
            else
              ...friendProvider.friends.map(
                (friend) => ListTile(
                  leading: CircleAvatar(
                    backgroundImage: friend.avatar != null
                        ? NetworkImage(friend.avatar!)
                        : null,
                    child: friend.avatar == null
                        ? Text(friend.username[0].toUpperCase())
                        : null,
                  ),
                  title: Text(friend.username),
                  subtitle: Text(friend.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (friend.isOnline)
                        Container(
                          width: 12,
                          height: 12,
                          decoration: const BoxDecoration(
                            color: Colors.green,
                            shape: BoxShape.circle,
                          ),
                        ),
                      const SizedBox(width: 8),
                      PopupMenuButton<String>(
                        onSelected: (value) =>
                            _handleFriendAction(value, friend),
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: 'message',
                            child: Text('Message'),
                          ),
                          const PopupMenuItem(
                            value: 'remove',
                            child: Text('Remove'),
                          ),
                          const PopupMenuItem(
                            value: 'block',
                            child: Text('Block'),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPendingRequests(FriendProvider friendProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Pending Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (friendProvider.pendingRequests.isEmpty)
              const Text('No pending requests')
            else
              ...friendProvider.pendingRequests.map((request) {
                final requester = request.requesterInfo;
                if (requester == null) return const SizedBox.shrink();

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(requester.username[0].toUpperCase()),
                  ),
                  title: Text(requester.username),
                  subtitle: Text(requester.email),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ElevatedButton(
                        onPressed: () =>
                            friendProvider.acceptFriendRequest(request.id),
                        child: const Text('Accept'),
                      ),
                      const SizedBox(width: 8),
                      TextButton(
                        onPressed: () =>
                            friendProvider.rejectFriendRequest(request.id),
                        child: const Text('Reject'),
                      ),
                    ],
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequests(FriendProvider friendProvider) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Sent Requests',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            if (friendProvider.sentRequests.isEmpty)
              const Text('No sent requests')
            else
              ...friendProvider.sentRequests.map((request) {
                final addressee = request.addresseeInfo;
                if (addressee == null) return const SizedBox.shrink();

                return ListTile(
                  leading: CircleAvatar(
                    child: Text(addressee.username[0].toUpperCase()),
                  ),
                  title: Text(addressee.username),
                  subtitle: Text(addressee.email),
                  trailing: TextButton(
                    onPressed: () =>
                        friendProvider.cancelFriendRequest(request.id),
                    child: const Text('Cancel'),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }

  Widget _buildFriendshipStatusChip(FriendshipStatus? status) {
    switch (status) {
      case FriendshipStatus.accepted:
        return const Chip(
          label: Text('Friends'),
          backgroundColor: Colors.green,
        );
      case FriendshipStatus.pending:
        return const Chip(
          label: Text('Pending'),
          backgroundColor: Colors.orange,
        );
      case FriendshipStatus.blocked:
        return const Chip(label: Text('Blocked'), backgroundColor: Colors.red);
      case FriendshipStatus.rejected:
        return const Chip(
          label: Text('Rejected'),
          backgroundColor: Colors.grey,
        );
      case null:
        return const Chip(label: Text('None'), backgroundColor: Colors.blue);
    }
  }

  void _handleFriendAction(String action, FriendUser friend) async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    switch (action) {
      case 'message':
        // Navigate to chat screen
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Starting chat with ${friend.username}')),
        );
        break;
      case 'remove':
        // Now we have the friendship ID from the friend object
        await friendProvider.removeFriend(friend.friendshipId);
        break;
      case 'block':
        await friendProvider.blockUser(friend.id);
        break;
    }
  }
}
