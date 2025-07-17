import 'user.dart';

class FriendUser extends User {
  final String friendshipId;

  FriendUser({
    required super.id,
    required super.username,
    required super.email,
    super.fullName,
    super.avatar,
    required super.isPremium,
    required super.isOnline,
    super.lastSeen,
    required super.createdAt,
    required super.updatedAt,
    required this.friendshipId,
  });

  factory FriendUser.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);
    return FriendUser(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      avatar: user.avatar,
      isPremium: user.isPremium,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      friendshipId: json['friendshipId'] ?? '',
    );
  }

  factory FriendUser.fromUser(User user, String friendshipId) {
    return FriendUser(
      id: user.id,
      username: user.username,
      email: user.email,
      fullName: user.fullName,
      avatar: user.avatar,
      isPremium: user.isPremium,
      isOnline: user.isOnline,
      lastSeen: user.lastSeen,
      createdAt: user.createdAt,
      updatedAt: user.updatedAt,
      friendshipId: friendshipId,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'username': username,
      'email': email,
      'fullName': fullName,
      'avatar': avatar,
      'isPremium': isPremium,
      'isOnline': isOnline,
      'lastSeen': lastSeen?.toIso8601String(),
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'friendshipId': friendshipId,
    };
  }
}
