import 'package:flutter/foundation.dart';
import '../models/user.dart';
import '../models/friend_user.dart';
import '../models/friendship.dart';
import '../models/user_with_friendship.dart';
import '../models/websocket_event.dart';
import '../services/friend_service.dart';
import '../services/websocket_service.dart';
import 'dart:async';

class FriendProvider with ChangeNotifier {
  final WebSocketService _webSocketService;
  StreamSubscription<WebSocketEvent>? _wsSubscription;

  // State
  List<FriendUser> _friends = [];
  List<Friendship> _pendingRequests = [];
  List<Friendship> _sentRequests = [];
  List<UserWithFriendship> _searchResults = [];
  List<User> _blockedUsers = [];
  bool _loading = false;
  String? _error;

  // Getters
  List<FriendUser> get friends => _friends;
  List<Friendship> get pendingRequests => _pendingRequests;
  List<Friendship> get sentRequests => _sentRequests;
  List<UserWithFriendship> get searchResults => _searchResults;
  List<User> get blockedUsers => _blockedUsers;
  bool get loading => _loading;
  String? get error => _error;

  FriendProvider(this._webSocketService) {
    _subscribeToWebSocket();
  }

  void _subscribeToWebSocket() {
    _wsSubscription = _webSocketService.events.listen(_handleWebSocketEvent);
  }

  void _handleWebSocketEvent(WebSocketEvent event) {
    switch (event.type) {
      case 'friend_request':
        _handleFriendRequest(event.data);
        break;
      case 'friend_request_accepted':
        _handleFriendRequestAccepted(event.data);
        break;
      case 'friend_request_rejected':
        _handleFriendRequestRejected(event.data);
        break;
      case 'friend_request_cancelled':
        _handleFriendRequestCancelled(event.data);
        break;
      case 'friend_removed':
        _handleFriendRemoved(event.data);
        break;
      case 'user_blocked':
        _handleUserBlocked(event.data);
        break;
      case 'user_unblocked':
        _handleUserUnblocked(event.data);
        break;
    }
  }

  void _handleFriendRequest(Map<String, dynamic> data) {
    try {
      final friendship = Friendship.fromJson(data['friendship']);
      _pendingRequests.add(friendship);
      notifyListeners();
    } catch (e) {
      debugPrint('Error handling friend request: $e');
    }
  }

  void _handleFriendRequestAccepted(Map<String, dynamic> data) {
    try {
      final friendship = Friendship.fromJson(data['friendship']);

      // Remove from sent requests
      _sentRequests.removeWhere((req) => req.id == friendship.id);

      // Add to friends if accepter info is available
      if (data['accepterInfo'] != null) {
        final friend = User.fromJson(data['accepterInfo']);
        // For WebSocket events, we won't have friendshipId, so we'll use the friendship ID
        final friendUser = FriendUser.fromUser(friend, friendship.id);
        _friends.add(friendUser);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling friend request accepted: $e');
    }
  }

  void _handleFriendRequestRejected(Map<String, dynamic> data) {
    try {
      final friendship = Friendship.fromJson(data['friendship']);

      // Remove from sent requests
      _sentRequests.removeWhere((req) => req.id == friendship.id);

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling friend request rejected: $e');
    }
  }

  void _handleFriendRequestCancelled(Map<String, dynamic> data) {
    try {
      final friendshipId = data['friendshipId'] as String?;

      // Remove from pending requests
      if (friendshipId != null) {
        _pendingRequests.removeWhere((req) => req.id == friendshipId);
      }

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling friend request cancelled: $e');
    }
  }

  void _handleFriendRemoved(Map<String, dynamic> data) {
    try {
      final userId = data['userId'] as String;

      // Remove from friends
      _friends.removeWhere((friend) => friend.id == userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling friend removed: $e');
    }
  }

  void _handleUserBlocked(Map<String, dynamic> data) {
    try {
      final userId = data['userId'] as String;

      // Remove from friends
      _friends.removeWhere((friend) => friend.id == userId);

      // Remove from pending and sent requests
      _pendingRequests.removeWhere(
        (req) => req.requester == userId || req.addressee == userId,
      );
      _sentRequests.removeWhere(
        (req) => req.requester == userId || req.addressee == userId,
      );

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling user blocked: $e');
    }
  }

  void _handleUserUnblocked(Map<String, dynamic> data) {
    try {
      final userId = data['userId'] as String;

      // Remove from blocked users
      _blockedUsers.removeWhere((user) => user.id == userId);

      notifyListeners();
    } catch (e) {
      debugPrint('Error handling user unblocked: $e');
    }
  }

  // API Methods
  Future<void> loadFriends() async {
    try {
      _setLoading(true);
      _friends = await FriendService.getFriends();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadPendingRequests() async {
    try {
      _setLoading(true);
      _pendingRequests = await FriendService.getPendingRequests();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadSentRequests() async {
    try {
      _setLoading(true);
      _sentRequests = await FriendService.getSentRequests();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> loadBlockedUsers() async {
    try {
      _setLoading(true);
      _blockedUsers = await FriendService.getBlockedUsers();
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> searchUsers(String query) async {
    if (query.trim().isEmpty) {
      _searchResults = [];
      notifyListeners();
      return;
    }

    try {
      _setLoading(true);
      _searchResults = await FriendService.searchUsers(query);
      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> sendFriendRequest(String userId) async {
    try {
      _setLoading(true);
      final friendship = await FriendService.sendFriendRequest(userId);
      _sentRequests.add(friendship);

      // Update search results
      _searchResults = _searchResults.map((user) {
        if (user.id == userId) {
          return UserWithFriendship.fromUser(
            user,
            friendshipStatus: FriendshipStatus.pending,
          );
        }
        return user;
      }).toList();

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> acceptFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      await FriendService.acceptFriendRequest(requestId);

      // Find the original request
      final originalRequest = _pendingRequests.firstWhere(
        (req) => req.id == requestId,
      );

      // Remove from pending requests
      _pendingRequests.removeWhere((req) => req.id == requestId);

      // Add to friends
      if (originalRequest.requesterInfo != null) {
        final friendUser = FriendUser.fromUser(
          originalRequest.requesterInfo!,
          requestId,
        );
        _friends.add(friendUser);
      }

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> rejectFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      await FriendService.rejectFriendRequest(requestId);

      // Remove from pending requests
      _pendingRequests.removeWhere((req) => req.id == requestId);

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> cancelFriendRequest(String requestId) async {
    try {
      _setLoading(true);
      await FriendService.cancelFriendRequest(requestId);

      // Remove from sent requests
      _sentRequests.removeWhere((req) => req.id == requestId);

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> removeFriend(String friendshipId) async {
    try {
      _setLoading(true);
      await FriendService.removeFriend(friendshipId);

      // Remove from friends using friendship ID
      _friends.removeWhere((friend) => friend.friendshipId == friendshipId);

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> blockUser(String userId) async {
    try {
      _setLoading(true);
      await FriendService.blockUser(userId);

      // Remove from friends
      _friends.removeWhere((friend) => friend.id == userId);

      // Remove from pending and sent requests
      _pendingRequests.removeWhere(
        (req) => req.requester == userId || req.addressee == userId,
      );
      _sentRequests.removeWhere(
        (req) => req.requester == userId || req.addressee == userId,
      );

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<void> unblockUser(String userId) async {
    try {
      _setLoading(true);
      await FriendService.unblockUser(userId);

      // Remove from blocked users
      _blockedUsers.removeWhere((user) => user.id == userId);

      _setError(null);
    } catch (e) {
      _setError(e.toString());
    } finally {
      _setLoading(false);
    }
  }

  Future<FriendshipStatus?> getFriendshipStatus(String userId) async {
    try {
      return await FriendService.getFriendshipStatus(userId);
    } catch (e) {
      _setError(e.toString());
      return null;
    }
  }

  // Helper methods
  void _setLoading(bool loading) {
    _loading = loading;
    notifyListeners();
  }

  void _setError(String? error) {
    _error = error;
    notifyListeners();
  }

  void clearError() {
    _error = null;
    notifyListeners();
  }

  void clearSearchResults() {
    _searchResults = [];
    notifyListeners();
  }

  @override
  void dispose() {
    _wsSubscription?.cancel();
    super.dispose();
  }
}
