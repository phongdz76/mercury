# Reply To Message Feature - Usage Guide

## Tổng quan

Tính năng Reply To cho phép người dùng trả lời trực tiếp một tin nhắn cụ thể trong cuộc trò chuyện, tạo ra luồng hội thoại rõ ràng và dễ theo dõi.

## Các tính năng đã được thêm vào ChatProvider

### 1. State Management

- `_replyingToMessages`: Map lưu trữ tin nhắn đang được reply cho mỗi conversation
- `replyingToMessages`: Getter để truy cập state từ UI

### 2. Reply State Management Methods

#### Thiết lập Reply

```dart
// Thiết lập tin nhắn để reply
chatProvider.setReplyToMessage(conversationId, message);

// Kiểm tra có đang reply không
bool isReplying = chatProvider.isReplyingTo(conversationId);

// Lấy tin nhắn đang được reply
Message? replyingMessage = chatProvider.getReplyToMessage(conversationId);

// Xóa trạng thái reply
chatProvider.clearReplyToMessage(conversationId);
```

### 3. Message Information Methods

#### Lấy thông tin tin nhắn được reply

```dart
// Lấy tin nhắn được reply theo ID
Message? repliedMessage = chatProvider.getRepliedMessage(conversationId, messageId);

// Lấy tin nhắn gốc trong chuỗi reply
Message? originalMessage = chatProvider.getOriginalMessage(conversationId, messageId);

// Lấy độ sâu của chuỗi reply
int depth = chatProvider.getReplyChainDepth(conversationId, messageId);
```

#### Thông tin về replies

```dart
// Lấy tất cả replies của một tin nhắn
List<Message> replies = chatProvider.getRepliesToMessage(conversationId, messageId);

// Kiểm tra tin nhắn có replies không
bool hasReplies = chatProvider.hasReplies(conversationId, messageId);

// Đếm số lượng replies
int replyCount = chatProvider.getReplyCount(conversationId, messageId);
```

### 4. Sending Messages with Reply

#### Gửi tin nhắn reply đơn giản

```dart
await chatProvider.sendReplyMessage(
  conversationId: conversationId,
  content: "This is a reply",
  replyToMessageId: originalMessage.id,
  type: 'text',
);
```

#### Gửi tin nhắn với attachments và reply

```dart
await chatProvider.sendMessageWithPendingAttachmentsAndReply(
  conversationId: conversationId,
  content: "Reply with attachments",
  replyToMessageId: originalMessage.id,
);
```

#### Gửi tin nhắn với auto-reply detection

```dart
// Nếu đang ở trạng thái reply, sẽ tự động gửi làm reply message
await chatProvider.sendMessageWithPendingAttachments(
  conversationId: conversationId,
  content: "This will be sent as reply if currently replying",
);
```

## Cách sử dụng trong UI

### 1. Message List UI

```dart
Widget buildMessage(Message message) {
  return Column(
    children: [
      // Hiển thị tin nhắn được reply (nếu có)
      if (message.replyTo != null)
        buildReplyContext(message),

      // Tin nhắn chính
      buildMainMessage(message),

      // Reply button
      buildReplyButton(message),
    ],
  );
}

Widget buildReplyContext(Message message) {
  final repliedMessage = chatProvider.getRepliedMessage(
    message.conversationId,
    message.replyTo!
  );

  if (repliedMessage == null) {
    return Container(
      padding: EdgeInsets.all(8),
      child: Text("Message not found", style: TextStyle(fontStyle: FontStyle.italic)),
    );
  }

  return Container(
    margin: EdgeInsets.only(bottom: 4),
    padding: EdgeInsets.all(8),
    decoration: BoxDecoration(
      color: Colors.grey[200],
      borderRadius: BorderRadius.circular(8),
      border: Border(left: BorderSide(color: Colors.blue, width: 3)),
    ),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          chatProvider.getUserDisplayName(repliedMessage.sender),
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
        ),
        Text(
          repliedMessage.content,
          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    ),
  );
}

Widget buildReplyButton(Message message) {
  return IconButton(
    icon: Icon(Icons.reply),
    onPressed: () {
      chatProvider.setReplyToMessage(conversationId, message);
    },
  );
}
```

### 2. Message Input UI

```dart
Widget buildMessageInput() {
  return Consumer<ChatProvider>(
    builder: (context, chatProvider, child) {
      final replyingMessage = chatProvider.getReplyToMessage(conversationId);

      return Column(
        children: [
          // Reply preview
          if (replyingMessage != null)
            buildReplyPreview(replyingMessage),

          // Message input
          buildTextInput(),
        ],
      );
    },
  );
}

Widget buildReplyPreview(Message replyingMessage) {
  return Container(
    padding: EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: Colors.blue[50],
      border: Border(left: BorderSide(color: Colors.blue, width: 3)),
    ),
    child: Row(
      children: [
        Icon(Icons.reply, size: 16, color: Colors.blue),
        SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Replying to ${chatProvider.getUserDisplayName(replyingMessage.sender)}",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
              ),
              Text(
                replyingMessage.content,
                style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
        IconButton(
          icon: Icon(Icons.close, size: 16),
          onPressed: () {
            chatProvider.clearReplyToMessage(conversationId);
          },
        ),
      ],
    ),
  );
}
```

### 3. Send Message Handler

```dart
Future<void> sendMessage() async {
  final content = messageController.text.trim();
  if (content.isEmpty && !chatProvider.hasPendingAttachments(conversationId)) {
    return;
  }

  // Sử dụng method tự động detect reply state
  await chatProvider.sendMessageWithPendingAttachments(
    conversationId: conversationId,
    content: content,
  );

  messageController.clear();
}
```

## Lưu ý khi implement

### 1. UI/UX Considerations

- Hiển thị rõ ràng tin nhắn đang được reply
- Cho phép cancel reply dễ dàng
- Limit độ sâu của reply chain để tránh UI phức tạp
- Preview tin nhắn được reply trong input area

### 2. Performance

- Cache tin nhắn được reply để tránh tìm kiếm nhiều lần
- Limit số lượng reply hiển thị trong nested replies
- Lazy load reply context khi cần thiết

### 3. Data Consistency

- Reply state được clear khi leave conversation
- Reply state được clear khi send message thành công
- Validate tin nhắn được reply vẫn tồn tại

### 4. Error Handling

- Handle trường hợp tin nhắn được reply đã bị xóa
- Handle trường hợp conversation không tồn tại
- Gracefully handle nested reply quá sâu

## Testing

### Unit Tests cần kiểm tra:

1. Set/clear reply state
2. Reply chain depth calculation
3. Finding replied messages
4. Counting replies
5. Auto-clear reply after send

### Integration Tests:

1. Send reply message end-to-end
2. UI reply preview functionality
3. Reply state persistence during app lifecycle
