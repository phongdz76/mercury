class Message {
  final String id;
  final String conversationId;
  final String sender;
  final String content;
  final String type;
  final String? replyTo;
  final List<MessageAttachment>? attachments;
  final List<ReadReceipt>? readBy;
  final bool isEdited;
  final bool isDeleted;
  final DateTime createdAt;
  final DateTime updatedAt;
  final DateTime? editedAt;
  final DateTime? deletedAt;

  Message({
    required this.id,
    required this.conversationId,
    required this.sender,
    required this.content,
    required this.type,
    this.replyTo,
    this.attachments,
    this.readBy,
    required this.isEdited,
    required this.isDeleted,
    required this.createdAt,
    required this.updatedAt,
    this.editedAt,
    this.deletedAt,
  });

  factory Message.fromJson(Map<String, dynamic> json) {
    return Message(
      id: json['_id'] ?? '',
      conversationId: json['conversationId'] ?? '',
      sender: json['sender'] ?? '',
      content: json['content'] ?? '',
      type: json['type'] ?? 'TEXT',
      replyTo: json['replyTo'],
      attachments: json['attachments'] != null
          ? List<MessageAttachment>.from(
              json['attachments'].map((x) => MessageAttachment.fromJson(x)),
            )
          : null,
      readBy: json['readBy'] != null
          ? List<ReadReceipt>.from(
              json['readBy'].map((x) => ReadReceipt.fromJson(x)),
            )
          : null,
      isEdited: json['isEdited'] ?? false,
      isDeleted: json['isDeleted'] ?? false,
      createdAt: DateTime.parse(
        json['createdAt'] ?? DateTime.now().toIso8601String(),
      ),
      updatedAt: DateTime.parse(
        json['updatedAt'] ?? DateTime.now().toIso8601String(),
      ),
      editedAt: json['editedAt'] != null
          ? DateTime.parse(json['editedAt'])
          : null,
      deletedAt: json['deletedAt'] != null
          ? DateTime.parse(json['deletedAt'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      '_id': id,
      'conversationId': conversationId,
      'sender': sender,
      'content': content,
      'type': type,
      'replyTo': replyTo,
      'attachments': attachments?.map((x) => x.toJson()).toList(),
      'readBy': readBy?.map((x) => x.toJson()).toList(),
      'isEdited': isEdited,
      'isDeleted': isDeleted,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
      'editedAt': editedAt?.toIso8601String(),
      'deletedAt': deletedAt?.toIso8601String(),
    };
  }
}

class MessageAttachment {
  final String id;
  final String name;
  final String url;
  final String type;
  final int size;

  MessageAttachment({
    required this.id,
    required this.name,
    required this.url,
    required this.type,
    required this.size,
  });

  factory MessageAttachment.fromJson(Map<String, dynamic> json) {
    return MessageAttachment(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      url: json['url'] ?? '',
      type: json['type'] ?? '',
      size: json['size'] ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {'id': id, 'name': name, 'url': url, 'type': type, 'size': size};
  }
}

class ReadReceipt {
  final String userId;
  final DateTime readAt;

  ReadReceipt({required this.userId, required this.readAt});

  factory ReadReceipt.fromJson(Map<String, dynamic> json) {
    return ReadReceipt(
      userId: json['userId'] ?? '',
      readAt: DateTime.parse(
        json['readAt'] ?? DateTime.now().toIso8601String(),
      ),
    );
  }

  Map<String, dynamic> toJson() {
    return {'userId': userId, 'readAt': readAt.toIso8601String()};
  }
}
