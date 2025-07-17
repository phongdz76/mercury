import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../models/user.dart';
import '../models/friend_user.dart';
import '../models/friendship.dart';
import '../models/user_with_friendship.dart';
import 'base_service.dart';

class FriendService {
  static const String _friendsEndpoint = '/friends';

  // Get all accepted friends for the current user
  static Future<List<FriendUser>> getFriends() async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        final friends = data['friends'] as List;
        return friends.map((friend) => FriendUser.fromJson(friend)).toList();
      } else {
        throw HttpException('Failed to get friends: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error getting friends: $e');
    }
  }

  // Get all pending friend requests received by the current user
  static Future<List<Friendship>> getPendingRequests() async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/requests/pending'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        final requests = data['requests'] as List;
        return requests.map((request) => Friendship.fromJson(request)).toList();
      } else {
        throw HttpException(
          'Failed to get pending requests: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting pending requests: $e');
    }
  }

  // Get all pending friend requests sent by the current user
  static Future<List<Friendship>> getSentRequests() async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/requests/sent'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        final requests = data['requests'] as List;
        return requests.map((request) => Friendship.fromJson(request)).toList();
      } else {
        throw HttpException(
          'Failed to get sent requests: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting sent requests: $e');
    }
  }

  // Search for users to send friend requests to
  static Future<List<UserWithFriendship>> searchUsers(String query) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.get(
        Uri.parse(
          '${BaseService.baseUrl}$_friendsEndpoint/search?q=${Uri.encodeComponent(query)}',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        final users = data['users'] as List;
        return users.map((user) => UserWithFriendship.fromJson(user)).toList();
      } else {
        throw HttpException('Failed to search users: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error searching users: $e');
    }
  }

  // Send a friend request to another user
  static Future<Friendship> sendFriendRequest(String userId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.post(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/requests'),
        headers: headers,
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        return Friendship.fromJson(data['request']);
      } else {
        throw HttpException(
          'Failed to send friend request: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error sending friend request: $e');
    }
  }

  // Accept a pending friend request
  static Future<Friendship> acceptFriendRequest(String requestId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.patch(
        Uri.parse(
          '${BaseService.baseUrl}$_friendsEndpoint/requests/$requestId/accept',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        return Friendship.fromJson(data['friendship']);
      } else {
        throw HttpException(
          'Failed to accept friend request: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error accepting friend request: $e');
    }
  }

  // Reject a pending friend request
  static Future<Friendship> rejectFriendRequest(String requestId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.patch(
        Uri.parse(
          '${BaseService.baseUrl}$_friendsEndpoint/requests/$requestId/reject',
        ),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        return Friendship.fromJson(data['friendship']);
      } else {
        throw HttpException(
          'Failed to reject friend request: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error rejecting friend request: $e');
    }
  }

  // Cancel a sent friend request
  static Future<void> cancelFriendRequest(String requestId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.delete(
        Uri.parse(
          '${BaseService.baseUrl}$_friendsEndpoint/requests/$requestId',
        ),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw HttpException(
          'Failed to cancel friend request: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error canceling friend request: $e');
    }
  }

  // Remove an existing friend (unfriend)
  static Future<void> removeFriend(String friendshipId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.delete(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/$friendshipId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to remove friend: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error removing friend: $e');
    }
  }

  // Block a user
  static Future<Friendship> blockUser(String userId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.post(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/block'),
        headers: headers,
        body: json.encode({'userId': userId}),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        return Friendship.fromJson(data['friendship']);
      } else {
        throw HttpException('Failed to block user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error blocking user: $e');
    }
  }

  // Unblock a previously blocked user
  static Future<void> unblockUser(String userId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.delete(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/block/$userId'),
        headers: headers,
      );

      if (response.statusCode != 200) {
        throw HttpException('Failed to unblock user: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Error unblocking user: $e');
    }
  }

  // Get blocked users
  static Future<List<User>> getBlockedUsers() async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/blocked'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        final blockedUsers = data['blockedUsers'] as List;
        return blockedUsers.map((user) => User.fromJson(user)).toList();
      } else {
        throw HttpException(
          'Failed to get blocked users: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting blocked users: $e');
    }
  }

  // Get friendship status between current user and another user
  static Future<FriendshipStatus?> getFriendshipStatus(String userId) async {
    try {
      final headers = await BaseService.getHeaders();
      final response = await http.get(
        Uri.parse('${BaseService.baseUrl}$_friendsEndpoint/status/$userId'),
        headers: headers,
      );

      if (response.statusCode == 200) {
        final jsonData = json.decode(response.body);
        final data = BaseService.handleResponse(jsonData);
        final statusString = data['status'] as String?;
        if (statusString != null) {
          return FriendshipStatus.values.firstWhere(
            (e) => e.value == statusString,
            orElse: () => FriendshipStatus.pending,
          );
        }
      } else if (response.statusCode == 404) {
        return null; // No friendship exists
      } else {
        throw HttpException(
          'Failed to get friendship status: ${response.statusCode}',
        );
      }
    } catch (e) {
      throw Exception('Error getting friendship status: $e');
    }
    return null;
  }
}
