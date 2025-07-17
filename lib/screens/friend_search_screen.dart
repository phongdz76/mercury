import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/friend_provider.dart';
import '../models/user_with_friendship.dart';
import '../models/friendship.dart';

class FriendSearchScreen extends StatefulWidget {
  const FriendSearchScreen({Key? key}) : super(key: key);

  @override
  State<FriendSearchScreen> createState() => _FriendSearchScreenState();
}

class _FriendSearchScreenState extends State<FriendSearchScreen> {
  final _searchController = TextEditingController();
  bool _isSearching = false;

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Search Friends')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                labelText: 'Search users...',
                prefixIcon: const Icon(Icons.search),
                border: const OutlineInputBorder(),
                suffixIcon: _isSearching
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : null,
              ),
              onChanged: _onSearchChanged,
            ),
          ),
          Expanded(child: _buildSearchResults()),
        ],
      ),
    );
  }

  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      Provider.of<FriendProvider>(context, listen: false).clearSearchResults();
      return;
    }

    setState(() {
      _isSearching = true;
    });

    // Debounce search
    Future.delayed(const Duration(milliseconds: 500), () {
      if (_searchController.text.trim() == query.trim()) {
        Provider.of<FriendProvider>(
          context,
          listen: false,
        ).searchUsers(query).then((_) {
          if (mounted) {
            setState(() {
              _isSearching = false;
            });
          }
        });
      }
    });
  }

  Widget _buildSearchResults() {
    return Consumer<FriendProvider>(
      builder: (context, friendProvider, child) {
        if (friendProvider.searchResults.isEmpty && !_isSearching) {
          return const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.search, size: 64, color: Colors.grey),
                SizedBox(height: 16),
                Text('Search for users to add as friends'),
              ],
            ),
          );
        }

        if (friendProvider.error != null) {
          return Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text('Error: ${friendProvider.error}'),
                ElevatedButton(
                  onPressed: () => friendProvider.clearError(),
                  child: const Text('Dismiss'),
                ),
              ],
            ),
          );
        }

        return ListView.builder(
          itemCount: friendProvider.searchResults.length,
          itemBuilder: (context, index) {
            final user = friendProvider.searchResults[index];
            return _buildUserTile(user);
          },
        );
      },
    );
  }

  Widget _buildUserTile(UserWithFriendship user) {
    return ListTile(
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
      trailing: _buildActionButton(user),
    );
  }

  Widget _buildActionButton(UserWithFriendship user) {
    final friendProvider = Provider.of<FriendProvider>(context, listen: false);

    switch (user.friendshipStatus) {
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
        return ElevatedButton(
          onPressed: () => friendProvider.sendFriendRequest(user.id),
          child: const Text('Add Friend'),
        );
      case null:
        return ElevatedButton(
          onPressed: () => friendProvider.sendFriendRequest(user.id),
          child: const Text('Add Friend'),
        );
    }
  }
}
