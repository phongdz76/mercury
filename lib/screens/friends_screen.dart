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
      body: SafeArea(
        child: Column(
          children: [
            // Header with title and actions
            Padding(
              padding: const EdgeInsets.fromLTRB(24, 16, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      'Friends',
                      style: Theme.of(context).textTheme.headlineMedium
                          ?.copyWith(fontWeight: FontWeight.w600),
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.search_rounded),
                    onPressed: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => const FriendSearchScreen(),
                      ),
                    ),
                    style: IconButton.styleFrom(
                      backgroundColor: Theme.of(
                        context,
                      ).colorScheme.surfaceVariant,
                      foregroundColor: Theme.of(
                        context,
                      ).colorScheme.onSurfaceVariant,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  PopupMenuButton<String>(
                    icon: Icon(
                      Icons.more_vert_rounded,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
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
                              builder: (context) =>
                                  const FriendRequestsScreen(),
                            ),
                          );
                          break;
                      }
                    },
                    itemBuilder: (BuildContext context) =>
                        <PopupMenuEntry<String>>[
                          const PopupMenuItem<String>(
                            value: 'blocked',
                            child: Row(
                              children: [
                                Icon(Icons.block_rounded, size: 20),
                                SizedBox(width: 12),
                                Text('Blocked Users'),
                              ],
                            ),
                          ),
                          const PopupMenuItem<String>(
                            value: 'requests',
                            child: Row(
                              children: [
                                Icon(Icons.person_add_rounded, size: 20),
                                SizedBox(width: 12),
                                Text('Friend Requests'),
                              ],
                            ),
                          ),
                        ],
                  ),
                ],
              ),
            ),
            // Tab bar
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant,
                borderRadius: BorderRadius.circular(16),
              ),
              child: TabBar(
                controller: _tabController,
                indicatorSize: TabBarIndicatorSize.tab,
                indicator: BoxDecoration(
                  color: Theme.of(context).colorScheme.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                labelColor: Theme.of(context).colorScheme.onPrimary,
                unselectedLabelColor: Theme.of(
                  context,
                ).colorScheme.onSurfaceVariant,
                labelStyle: const TextStyle(
                  fontWeight: FontWeight.w600,
                  fontSize: 14,
                ),
                unselectedLabelStyle: const TextStyle(
                  fontWeight: FontWeight.w500,
                  fontSize: 14,
                ),
                tabs: const [
                  Tab(text: 'Friends'),
                  Tab(text: 'Requests'),
                  Tab(text: 'Sent'),
                ],
              ),
            ),
            const SizedBox(height: 16),
            // Content
            Expanded(
              child: TabBarView(
                controller: _tabController,
                children: [
                  _buildFriendsTab(),
                  _buildRequestsTab(),
                  _buildSentTab(),
                ],
              ),
            ),
          ],
        ),
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
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildFriendTile(friend),
              );
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
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildRequestTile(request),
              );
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
              return Container(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: _buildSentRequestTile(request),
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildFriendTile(FriendUser friend) {
    final colorScheme = Theme.of(context).colorScheme;

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (friend.isOnline)
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: colorScheme.tertiary,
                shape: BoxShape.circle,
              ),
            ),
          PopupMenuButton<String>(
            onSelected: (value) => _handleFriendAction(value, friend),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
            ),
            itemBuilder: (context) => [
              PopupMenuItem(
                value: 'message',
                child: ListTile(
                  leading: const Icon(Icons.message_rounded),
                  title: const Text('Message'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'remove',
                child: ListTile(
                  leading: const Icon(Icons.person_remove_rounded),
                  title: const Text('Remove Friend'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: 'block',
                child: ListTile(
                  leading: const Icon(Icons.block_rounded),
                  title: const Text('Block User'),
                  contentPadding: EdgeInsets.zero,
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      trailing: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          FilledButton.tonal(
            onPressed: () => _acceptRequest(request.id),
            child: const Text('Accept'),
          ),
          const SizedBox(width: 8),
          OutlinedButton(
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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      trailing: OutlinedButton(
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
