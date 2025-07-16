class WebSocketEvent {
  final String type;
  final String? conversationId;
  final Map<String, dynamic> data;
  final DateTime? timestamp;

  WebSocketEvent({
    required this.type,
    this.conversationId,
    required this.data,
    this.timestamp,
  });

  factory WebSocketEvent.fromJson(Map<String, dynamic> json) {
    return WebSocketEvent(
      type: json['type'] ?? '',
      conversationId: json['conversationId'],
      data: json['data'] ?? {},
      timestamp: json['timestamp'] != null
          ? DateTime.parse(json['timestamp'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'type': type,
      'conversationId': conversationId,
      'data': data,
      'timestamp': timestamp?.toIso8601String(),
    };
  }
}

class WebSocketMessage {
  final String type;
  final String conversationId;
  final Map<String, dynamic> data;

  WebSocketMessage({
    required this.type,
    required this.conversationId,
    required this.data,
  });

  Map<String, dynamic> toJson() {
    return {'type': type, 'conversationId': conversationId, 'data': data};
  }
}
