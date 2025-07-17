import 'user.dart';
import 'friendship.dart';

class UserWithFriendship extends User {
  final FriendshipStatus? friendshipStatus;

  UserWithFriendship({
    required String id,
    required String username,
    required String email,
    String? fullName,
    String? avatar,
    required bool isPremium,
    required bool isOnline,
    DateTime? lastSeen,
    required DateTime createdAt,
    required DateTime updatedAt,
    this.friendshipStatus,
  }) : super(
         id: id,
         username: username,
         email: email,
         fullName: fullName,
         avatar: avatar,
         isPremium: isPremium,
         isOnline: isOnline,
         lastSeen: lastSeen,
         createdAt: createdAt,
         updatedAt: updatedAt,
       );

  factory UserWithFriendship.fromJson(Map<String, dynamic> json) {
    final user = User.fromJson(json);

    FriendshipStatus? friendshipStatus;
    if (json['friendshipStatus'] != null) {
      friendshipStatus = FriendshipStatus.values.firstWhere(
        (e) => e.value == json['friendshipStatus'],
        orElse: () => FriendshipStatus.pending,
      );
    }

    return UserWithFriendship(
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
      friendshipStatus: friendshipStatus,
    );
  }

  factory UserWithFriendship.fromUser(
    User user, {
    FriendshipStatus? friendshipStatus,
  }) {
    return UserWithFriendship(
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
      friendshipStatus: friendshipStatus,
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
      if (friendshipStatus != null) 'friendshipStatus': friendshipStatus!.value,
    };
  }
}
