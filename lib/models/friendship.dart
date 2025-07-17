import 'user.dart';

class Friendship {
  final String id;
  final String requester;
  final String addressee;
  final FriendshipStatus status;
  final DateTime createdAt;
  final DateTime updatedAt;
  final User? requesterInfo;
  final User? addresseeInfo;

  Friendship({
    required this.id,
    required this.requester,
    required this.addressee,
    required this.status,
    required this.createdAt,
    required this.updatedAt,
    this.requesterInfo,
    this.addresseeInfo,
  });

  factory Friendship.fromJson(Map<String, dynamic> json) {
    return Friendship(
      id: json['_id'] ?? '',
      requester: json['requester'] ?? '',
      addressee: json['addressee'] ?? '',
      status: FriendshipStatus.values.firstWhere(
        (e) => e.value == json['status'],
        orElse: () => FriendshipStatus.pending,
      ),
      createdAt: DateTime.parse(json['createdAt']),
      updatedAt: DateTime.parse(json['updatedAt']),
      requesterInfo: json['requesterInfo'] != null
          ? User.fromJson(json['requesterInfo'])
          : null,
      addresseeInfo: json['addresseeInfo'] != null
          ? User.fromJson(json['addresseeInfo'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'requester': requester,
      'addressee': addressee,
      'status': status.value,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      if (requesterInfo != null)
        'requesterInfo': {
          '_id': requesterInfo!.id,
          'username': requesterInfo!.username,
          'email': requesterInfo!.email,
          'fullName': requesterInfo!.fullName,
          'avatar': requesterInfo!.avatar,
          'isPremium': requesterInfo!.isPremium,
          'isOnline': requesterInfo!.isOnline,
          'lastSeen': requesterInfo!.lastSeen?.toIso8601String(),
        },
      if (addresseeInfo != null)
        'addresseeInfo': {
          '_id': addresseeInfo!.id,
          'username': addresseeInfo!.username,
          'email': addresseeInfo!.email,
          'fullName': addresseeInfo!.fullName,
          'avatar': addresseeInfo!.avatar,
          'isPremium': addresseeInfo!.isPremium,
          'isOnline': addresseeInfo!.isOnline,
          'lastSeen': addresseeInfo!.lastSeen?.toIso8601String(),
        },
    };
  }

  Friendship copyWith({
    String? id,
    String? requester,
    String? addressee,
    FriendshipStatus? status,
    DateTime? createdAt,
    DateTime? updatedAt,
    User? requesterInfo,
    User? addresseeInfo,
  }) {
    return Friendship(
      id: id ?? this.id,
      requester: requester ?? this.requester,
      addressee: addressee ?? this.addressee,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      requesterInfo: requesterInfo ?? this.requesterInfo,
      addresseeInfo: addresseeInfo ?? this.addresseeInfo,
    );
  }
}

enum FriendshipStatus {
  pending('pending'),
  accepted('accepted'),
  rejected('rejected'),
  blocked('blocked');

  const FriendshipStatus(this.value);
  final String value;
}
