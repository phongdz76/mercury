import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/friend_user.dart';
import '../models/friendship.dart';
import 'friend_search_screen.dart';
import 'friend_requests_screen.dart';
import 'blocked_users_screen.dart';

class FriendsScreen extends StatefulWidget {
  const FriendsScreen({Key? key}) : super(key: key);

  @override
  State<FriendsScreen> createState() => _FriendsScreenState();
}

class _FriendsScreenState extends State<FriendsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _loadData();
  }

  Future<void> _loadData() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await Future.wait([
      friendProvider.loadFriends(),
      friendProvider.loadPendingRequests(),
      friendProvider.loadSentRequests(),
    ]);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Friends'),
        bottom: TabBar(
          controller: _tabController,
          tabs: [
            Tab(text: 'Friends'),
            Tab(text: 'Requests'),
            Tab(text: 'Sent'),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.search),
            onPressed: () => Navigator.push(
              context,
              MaterialPageRoute(
                builder: (context) => const FriendSearchScreen(),
              ),
            ),
          ),
          PopupMenuButton<String>(
            onSelected: (String value) {
              switch (value) {
                case 'blocked':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const BlockedUsersScreen(),
                    ),
                  );
                  break;
                case 'requests':
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const FriendRequestsScreen(),
                    ),
                  );
                  break;
              }
            },
            itemBuilder: (BuildContext context) => <PopupMenuEntry<String>>[
              const PopupMenuItem<String>(
                value: 'blocked',
                child: Text('Blocked Users'),
              ),
              const PopupMenuItem<String>(
                value: 'requests',
                child: Text('Friend Requests'),
              ),
            ],
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildFriendsTab(), _buildRequestsTab(), _buildSentTab()],
      ),
    );
  }

  Widget _buildFriendsTab() {
    return Consumer<FriendProvider>(
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
                Icon(Icons.people_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No friends yet'),
                SizedBox(height: 8),
                Text('Search for users to add as friends'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => friendProvider.loadFriends(),
          child: ListView.builder(
            itemCount: friendProvider.friends.length,
            itemBuilder: (context, index) {
              final friend = friendProvider.friends[index];
              return _buildFriendTile(friend);
            },
          ),
        );
      },
    );
  }

  Widget _buildRequestsTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        if (friendProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendProvider.pendingRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.mail_outline, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No pending requests'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => friendProvider.loadPendingRequests(),
          child: ListView.builder(
            itemCount: friendProvider.pendingRequests.length,
            itemBuilder: (context, index) {
              final request = friendProvider.pendingRequests[index];
              return _buildRequestTile(request);
            },
          ),
        );
      },
    );
  }

  Widget _buildSentTab() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        if (friendProvider.loading) {
          return const Center(child: CircularProgressIndicator());
        }

        if (friendProvider.sentRequests.isEmpty) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.send_outlined, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('No sent requests'),
              ],
            ),
          );
        }

        return RefreshIndicator(
          onRefresh: () => friendProvider.loadSentRequests(),
          child: ListView.builder(
            itemCount: friendProvider.sentRequests.length,
            itemBuilder: (context, index) {
              final request = friendProvider.sentRequests[index];
              return _buildSentRequestTile(request);
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendTile(FriendUser friend) {
    return ListTile(
      leading: CircleAvatar(
        backgroundImage: friend.avatar != null
            ? NetworkImage(friend.avatar!)
            : null,
        child: friend.avatar == null
            ? Text(friend.username[0].toUpperCase())
            : null,
      ),
      title: Text(friend.username),
      subtitle: Text(friend.fullName ?? friend.email),
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
          PopupMenuButton<String>(
            onSelected: (value) => _handleFriendAction(value, friend),
            itemBuilder: (context) => [
              const PopupMenuItem(
                value: 'message',
                child: ListTile(
                  leading: Icon(Icons.message),
                  title: Text('Message'),
                ),
              ),
              const PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: Icon(Icons.person_remove),
                  title: Text('Remove Friend'),
                ),
              ),
              const PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: Icon(Icons.block),
                  title: Text('Block User'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildRequestTile(Friendship request) {
    final requester = request.requesterInfo;
    if (requester == null) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: requester.avatar != null
            ? NetworkImage(requester.avatar!)
            : null,
        child: requester.avatar == null
            ? Text(requester.username[0].toUpperCase())
            : null,
      ),
      title: Text(requester.username),
      subtitle: Text(requester.fullName ?? requester.email),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          TextButton(
            onPressed: () => _acceptRequest(request.id),
            child: const Text('Accept'),
          ),
          TextButton(
            onPressed: () => _rejectRequest(request.id),
            child: const Text('Reject'),
          ),
        ],
      ),
    );
  }

  Widget _buildSentRequestTile(Friendship request) {
    final addressee = request.addresseeInfo;
    if (addressee == null) return const SizedBox.shrink();

    return ListTile(
      leading: CircleAvatar(
        backgroundImage: addressee.avatar != null
            ? NetworkImage(addressee.avatar!)
            : null,
        child: addressee.avatar == null
            ? Text(addressee.username[0].toUpperCase())
            : null,
      ),
      title: Text(addressee.username),
      subtitle: Text(addressee.fullName ?? addressee.email),
      trailing: TextButton(
        onPressed: () => _cancelRequest(request.id),
        child: const Text('Cancel'),
      ),
    );
  }

  void _handleFriendAction(String action, FriendUser friend) async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    switch (action) {
      case 'message':
        // Navigate to chat screen
        break;
      case 'remove':
        final confirmed = await _showConfirmDialog(
          'Remove Friend',
          'Are you sure you want to remove ${friend.username} as a friend?',
        );
        if (confirmed) {
          // Now we have the friendship ID from the friend object
          await friendProvider.removeFriend(friend.friendshipId);
        }
        break;
      case 'block':
        final confirmed = await _showConfirmDialog(
          'Block User',
          'Are you sure you want to block ${friend.username}?',
        );
        if (confirmed) {
          await friendProvider.blockUser(friend.id);
        }
        break;
    }
  }

  Future<void> _acceptRequest(String requestId) async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.acceptFriendRequest(requestId);
  }

  Future<void> _rejectRequest(String requestId) async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.rejectFriendRequest(requestId);
  }

  Future<void> _cancelRequest(String requestId) async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.cancelFriendRequest(requestId);
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
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }
}
