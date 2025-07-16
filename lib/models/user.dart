class User {
  final String id;
  final String username;
  final String email;
  final String? fullName;
  final String? avatar;
  final bool isPremium;
  final bool isOnline;
  final DateTime? lastSeen;
  final DateTime createdAt;
  final DateTime updatedAt;

  User({
    required this.id,
    required this.username,
    required this.email,
    this.fullName,
    this.avatar,
    required this.isPremium,
    required this.isOnline,
    this.lastSeen,
    required this.createdAt,
    required this.updatedAt,
  });

  factory User.fromJson(Map<String, dynamic> json) {
    // Handle empty string fullName
    String? fullName = json['fullName'];
    if (fullName != null && fullName.isEmpty) {
      fullName = null;
    }

    return User(
      id: json['id'] ?? json['_id'] ?? '',
      username: json['username'] ?? '',
      email: json['email'] ?? '',
      fullName: fullName,
      avatar: json['avatar']?.isNotEmpty == true ? json['avatar'] : null,
      isPremium: json['isPremium'] ?? false,
      isOnline: json['isOnline'] ?? false,
      lastSeen: json['lastSeen'] != null
          ? DateTime.parse(json['lastSeen'])
          : null,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }
}
