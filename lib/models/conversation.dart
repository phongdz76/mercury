class Conversation {
  final String id;
  final String type;
  final List<String> participants;
  final String? title;
  final String? description;
  final String createdBy;
  final String? lastMessage;
  final DateTime lastActivity;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final String? lastMessageType;
  final String? lastMessageSender;

  Conversation({
    required this.id,
    required this.type,
    required this.participants,
    this.title,
    this.description,
    required this.createdBy,
    this.lastMessage,
    required this.lastActivity,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
    this.unreadCount = 0,
    this.isMuted = false,
    this.isArchived = false,
    this.lastMessageType,
    this.lastMessageSender,
  });

  factory Conversation.fromJson(Map<String, dynamic> json) {
    return Conversation(
      id: json['_id'] ?? '',
      type: json['type'] ?? 'DIRECT',
      participants: List<String>.from(json['participants'] ?? []),
      title: json['title'],
      description: json['description'],
      createdBy: json['createdBy'] ?? '',
      lastMessage: json['lastMessage'],
      lastActivity: DateTime.parse(
        json['lastActivity'] ?? DateTime.now().toIso8601String(),
      ),
      isActive: json['isActive'] ?? true,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      unreadCount: json['unreadCount'] ?? 0,
      isMuted: json['isMuted'] ?? false,
      isArchived: json['isArchived'] ?? false,
      lastMessageType: json['lastMessageType'],
      lastMessageSender: json['lastMessageSender'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'type': type,
      'participants': participants,
      'title': title,
      'description': description,
      'createdBy': createdBy,
      'lastMessage': lastMessage,
      'lastActivity': lastActivity.toIso8601String(),
      'isActive': isActive,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'unreadCount': unreadCount,
      'isMuted': isMuted,
      'isArchived': isArchived,
      'lastMessageType': lastMessageType,
      'lastMessageSender': lastMessageSender,
    };
  }

  // Helper method to create a copy with updated properties
  Conversation copyWith({
    String? id,
    String? type,
    List<String>? participants,
    String? title,
    String? description,
    String? createdBy,
    String? lastMessage,
    DateTime? lastActivity,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
    int? unreadCount,
    bool? isMuted,
    bool? isArchived,
    String? lastMessageType,
    String? lastMessageSender,
  }) {
    return Conversation(
      id: id ?? this.id,
      type: type ?? this.type,
      participants: participants ?? this.participants,
      title: title ?? this.title,
      description: description ?? this.description,
      createdBy: createdBy ?? this.createdBy,
      lastMessage: lastMessage ?? this.lastMessage,
      lastActivity: lastActivity ?? this.lastActivity,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
      unreadCount: unreadCount ?? this.unreadCount,
      isMuted: isMuted ?? this.isMuted,
      isArchived: isArchived ?? this.isArchived,
      lastMessageType: lastMessageType ?? this.lastMessageType,
      lastMessageSender: lastMessageSender ?? this.lastMessageSender,
    );
  }
}
