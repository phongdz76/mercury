# Message Sent Event & Real-time Updates

## Tổng quan

Đã thêm xử lý `message_sent` event để cập nhật danh sách cuộc trò chuyện khi tin nhắn được gửi thành công, cải thiện trải nghiệm người dùng với phản hồi tức thì.

## Tính năng mới được thêm

### 1. Xử lý Message Sent Event

- **`message_sent`**: Cập nhật cuộc trò chuyện khi tin nhắn được gửi thành công
- **`message_delivered`**: Cập nhật trạng thái tin nhắn khi được giao thành công
- **`message_failed`**: Xử lý khi tin nhắn gửi thất bại

### 2. Pending Message System

- **Tin nhắn tạm thời**: Hiển thị tin nhắn ngay lập tức khi người dùng gửi
- **Cập nhật thời gian thực**: Thay thế tin nhắn tạm thời bằng tin nhắn thực từ server
- **Trạng thái tin nhắn**: Hỗ trợ các trạng thái pending, sent, delivered, failed

### 3. Cải tiến Conversation Updates

- **Cập nhật tức thì**: Danh sách cuộc trò chuyện cập nhật ngay khi gửi tin nhắn
- **Sắp xếp tự động**: Cuộc trò chuyện tự động di chuyển lên đầu khi có tin nhắn mới
- **Loại bỏ trùng lặp**: Kiểm tra tin nhắn trùng lặp trước khi thêm vào danh sách

## Cải tiến kỹ thuật

### WebSocket Event Handlers

```dart
void _handleMessageSent(WebSocketEvent event) {
  // Xử lý khi tin nhắn được gửi thành công
  // Cập nhật danh sách tin nhắn và cuộc trò chuyện
}

void _handleMessageDelivered(WebSocketEvent event) {
  // Xử lý khi tin nhắn được giao thành công
  // Cập nhật trạng thái delivery
}

void _handleMessageFailed(WebSocketEvent event) {
  // Xử lý khi tin nhắn gửi thất bại
  // Hiển thị thông báo lỗi
}
```

### Enhanced Send Message Flow

```dart
Future<void> sendMessage({
  required String conversationId,
  required String content,
  String type = 'text',
  String? replyTo,
}) async {
  // 1. Tạo tin nhắn pending
  final pendingMessage = Message(...);

  // 2. Thêm vào UI ngay lập tức
  _messages[conversationId]!.add(pendingMessage);

  // 3. Cập nhật conversation list
  _updateConversationLastMessage(conversationId, content, type);

  // 4. Gửi qua WebSocket
  _webSocketService.sendMessage(...);

  // 5. Gửi qua REST API (backup)
  await ApiService.sendMessage(...);

  // 6. Xóa tin nhắn pending (sẽ được thay thế bởi WebSocket event)
  _messages[conversationId]?.removeWhere((m) => m.id == pendingMessage.id);
}
```

### Helper Methods

```dart
void _updateConversationLastMessage(String conversationId, String content, String type) {
  // Cập nhật tin nhắn cuối và thời gian hoạt động
  // Sắp xếp lại danh sách cuộc trò chuyện
}
```

## Lợi ích

### User Experience

- **Phản hồi tức thì**: Tin nhắn hiển thị ngay lập tức khi gửi
- **Cập nhật real-time**: Danh sách cuộc trò chuyện cập nhật tự động
- **Trạng thái tin nhắn**: Người dùng biết được trạng thái tin nhắn (pending, sent, delivered, failed)
- **Không bị trùng lặp**: Tin nhắn không bị hiển thị nhiều lần

### Technical Benefits

- **Đồng bộ tốt hơn**: WebSocket event đảm bảo đồng bộ giữa client và server
- **Xử lý lỗi**: Có thể xử lý các trường hợp tin nhắn gửi thất bại
- **Performance**: Cập nhật chỉ những gì thay đổi
- **Consistency**: Dữ liệu luôn nhất quán giữa các client

## Cách sử dụng

### Gửi tin nhắn

```dart
await chatProvider.sendMessage(
  conversationId: 'conversation_id',
  content: 'Hello world!',
  type: 'text',
);
```

### Gửi tin nhắn với file

```dart
await chatProvider.sendMessageWithFile(
  conversationId: 'conversation_id',
  file: selectedFile,
  type: 'image',
  caption: 'My photo',
);
```

### Xử lý WebSocket events

Các event được xử lý tự động:

- `message_sent`: Tin nhắn gửi thành công
- `message_delivered`: Tin nhắn được giao
- `message_failed`: Tin nhắn gửi thất bại

## Kế hoạch tương lai

### Message Status UI

- Hiển thị icon trạng thái tin nhắn (pending, sent, delivered, read)
- Animation khi chuyển đổi trạng thái
- Retry button cho tin nhắn gửi thất bại

### Offline Support

- Queue tin nhắn khi offline
- Tự động gửi khi có kết nối
- Sync tin nhắn khi reconnect

### Advanced Features

- Message reactions
- Message forwarding
- Message scheduling
- Draft messages

## Troubleshooting

### Tin nhắn không hiển thị

1. Kiểm tra WebSocket connection
2. Verify event handlers được gọi
3. Check message ID không trùng lặp

### Danh sách không cập nhật

1. Kiểm tra `_updateConversationLastMessage` method
2. Verify `_sortConversations` được gọi
3. Check `notifyListeners()` được gọi

### Tin nhắn bị trùng lặp

1. Kiểm tra logic check duplicate trong `_handleMessageSent`
2. Verify pending message được xóa đúng cách
3. Check message ID generation

## Configuration

### WebSocket Events

- `message_sent`: Confirmation của tin nhắn gửi thành công
- `message_delivered`: Confirmation của tin nhắn được giao
- `message_failed`: Thông báo tin nhắn gửi thất bại

### Message Types

- `text`: Tin nhắn văn bản
- `image`: Hình ảnh (📷 Image)
- `file`: File (📁 File)
- `audio`: Audio (🎵 Audio)
- `video`: Video (🎥 Video)
- `location`: Vị trí (📍 Location)

Cải tiến này đảm bảo danh sách cuộc trò chuyện luôn được cập nhật real-time với trải nghiệm người dùng mượt mà và phản hồi tức thì.
