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
    };
  }
}
