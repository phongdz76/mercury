import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/friendship.dart';

class FriendRequestsScreen extends StatefulWidget {
  const FriendRequestsScreen({Key? key}) : super(key: key);

  @override
  State<FriendRequestsScreen> createState() => _FriendRequestsScreenState();
}

class _FriendRequestsScreenState extends State<FriendRequestsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadRequests();
  }

  Future<void> _loadRequests() async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await Future.wait([
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
        title: const Text('Friend Requests'),
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Received'),
            Tab(text: 'Sent'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [_buildReceivedTab(), _buildSentTab()],
      ),
    );
  }

  Widget _buildReceivedTab() {
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
                  onPressed: () => friendProvider.loadPendingRequests(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
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
              return _buildReceivedRequestTile(request);
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

        if (friendProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${friendProvider.error}'),
                ElevatedButton(
                  onPressed: () => friendProvider.loadSentRequests(),
                  child: const Text('Retry'),
                ),
              ],
            ),
          );
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

  Widget _buildReceivedRequestTile(Friendship request) {
    final requester = request.requesterInfo;
    if (requester == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: requester.avatar != null
              ? NetworkImage(requester.avatar!)
              : null,
          child: requester.avatar == null
              ? Text(requester.username[0].toUpperCase())
              : null,
        ),
        title: Text(requester.username),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(requester.fullName ?? requester.email),
            const SizedBox(height: 4),
            Text(
              'Sent ${_formatDate(request.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextButton(
              onPressed: () => _acceptRequest(request.id),
              style: TextButton.styleFrom(foregroundColor: Colors.green),
              child: const Text('Accept'),
            ),
            TextButton(
              onPressed: () => _rejectRequest(request.id),
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Reject'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSentRequestTile(Friendship request) {
    final addressee = request.addresseeInfo;
    if (addressee == null) return const SizedBox.shrink();

    return Card(
      margin: const EdgeInsets.all(8),
      child: ListTile(
        leading: CircleAvatar(
          backgroundImage: addressee.avatar != null
              ? NetworkImage(addressee.avatar!)
              : null,
          child: addressee.avatar == null
              ? Text(addressee.username[0].toUpperCase())
              : null,
        ),
        title: Text(addressee.username),
        subtitle: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(addressee.fullName ?? addressee.email),
            const SizedBox(height: 4),
            Text(
              'Sent ${_formatDate(request.createdAt)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
        trailing: TextButton(
          onPressed: () => _cancelRequest(request.id),
          style: TextButton.styleFrom(foregroundColor: Colors.red),
          child: const Text('Cancel'),
        ),
      ),
    );
  }

  Future<void> _acceptRequest(String requestId) async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.acceptFriendRequest(requestId);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request accepted')));
    }
  }

  Future<void> _rejectRequest(String requestId) async {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);
    await friendProvider.rejectFriendRequest(requestId);

    if (mounted) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Friend request rejected')));
    }
  }

  Future<void> _cancelRequest(String requestId) async {
    final confirmed = await _showConfirmDialog(
      'Cancel Request',
      'Are you sure you want to cancel this friend request?',
    );

    if (confirmed) {
      final friendProvider = Provider.of<FriendProvider>(
        context,
        listen: false,
      );
      await friendProvider.cancelFriendRequest(requestId);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Friend request cancelled')),
        );
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
                child: const Text('Confirm'),
              ),
            ],
          ),
        ) ??
        false;
  }

  String _formatDate(DateTime date) {
    final now = DateTime.now();
    final difference = now.difference(date);

    if (difference.inDays > 0) {
      return '${difference.inDays}d ago';
    } else if (difference.inHours > 0) {
      return '${difference.inHours}h ago';
    } else if (difference.inMinutes > 0) {
      return '${difference.inMinutes}m ago';
    } else {
      return 'Just now';
    }
  }
}
