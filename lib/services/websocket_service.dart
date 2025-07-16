import 'dart:convert';
import 'dart:async';
import 'package:web_socket_channel/web_socket_channel.dart';
import 'package:web_socket_channel/status.dart' as status;
import '../models/websocket_event.dart';
import '../constants/app_constants.dart';
import 'api_service.dart';

class WebSocketService {
  static const String wsUrl = ApiConstants.wsUrl;

  WebSocketChannel? _channel;
  final StreamController<WebSocketEvent> _eventController =
      StreamController<WebSocketEvent>.broadcast();
  bool _isConnected = false;
  Timer? _reconnectTimer;
  Timer? _pingTimer;

  Stream<WebSocketEvent> get events => _eventController.stream;
  bool get isConnected => _isConnected;

  Future<void> connect() async {
    try {
      final token = await ApiService.getToken();
      if (token == null) {
        throw Exception('No authentication token found');
      }

      _channel = WebSocketChannel.connect(Uri.parse('$wsUrl?token=$token'));

      _isConnected = true;
      _startPingTimer();

      _channel!.stream.listen(
        (data) {
          try {
            final Map<String, dynamic> json = jsonDecode(data);
            final event = WebSocketEvent.fromJson(json);
            _eventController.add(event);
          } catch (e) {
            print('Error parsing WebSocket message: $e');
          }
        },
        onError: (error) {
          print('WebSocket error: $error');
          _handleDisconnection();
        },
        onDone: () {
          print('WebSocket connection closed');
          _handleDisconnection();
        },
      );
    } catch (e) {
      print('Failed to connect to WebSocket: $e');
      _handleDisconnection();
    }
  }

  void _handleDisconnection() {
    _isConnected = false;
    _pingTimer?.cancel();
    _startReconnectTimer();
  }

  void _startReconnectTimer() {
    _reconnectTimer?.cancel();
    _reconnectTimer = Timer(const Duration(seconds: 5), () {
      if (!_isConnected) {
        print('Attempting to reconnect...');
        connect();
      }
    });
  }

  void _startPingTimer() {
    _pingTimer?.cancel();
    _pingTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      if (_isConnected) {
        _send({'type': 'ping', 'data': {}});
      }
    });
  }

  void _send(Map<String, dynamic> message) {
    if (_isConnected && _channel != null) {
      _channel!.sink.add(jsonEncode(message));
    }
  }

  void joinConversation(String conversationId) {
    _send({
      'type': 'join_conversation',
      'conversationId': conversationId,
      'data': {},
    });
  }

  void sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyTo,
  }) {
    _send({
      'type': 'send_message',
      'conversationId': conversationId,
      'data': {'content': content, 'type': type, 'replyTo': replyTo},
    });
  }

  void sendTyping(String conversationId, bool isTyping) {
    _send({
      'type': 'typing',
      'conversationId': conversationId,
      'data': {'isTyping': isTyping},
    });
  }

  void markAsRead(String conversationId, String messageId) {
    _send({
      'type': 'mark_read',
      'conversationId': conversationId,
      'data': {'messageId': messageId},
    });
  }

  void leaveConversation(String conversationId) {
    _send({
      'type': 'leave_conversation',
      'conversationId': conversationId,
      'data': {},
    });
  }

  void disconnect() {
    _isConnected = false;
    _reconnectTimer?.cancel();
    _pingTimer?.cancel();
    _channel?.sink.close(status.goingAway);
    _channel = null;
  }

  void dispose() {
    disconnect();
    _eventController.close();
  }
}
