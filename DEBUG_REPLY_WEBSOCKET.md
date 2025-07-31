# 🔧 DEBUG: Reply WebSocket Issue

## 🚨 Vấn đề

WebSocket request không có field `replyTo` mặc dù đã implement:

```json
{
  "type": "send_message",
  "conversationId": "687890128187e1618608cbee",
  "data": {
    "content": "1231123",
    "type": "text"
    // ❌ Thiếu field "replyTo"
  }
}
```

## 🔍 Đã thêm Debug Logs

### 1. **ChatProvider.sendMessage()**

```dart
print('DEBUG: Auto-detected replyTo: $finalReplyTo');
print('DEBUG: Using provided replyTo: $finalReplyTo');
print('DEBUG: No reply state found for conversation: $conversationId');
print('DEBUG: Cleared reply state for conversation: $conversationId');
```

### 2. **WebSocketService.sendMessage()**

```dart
print('DEBUG: Adding replyTo to message: $replyTo');
print('DEBUG: No replyTo provided');
print('DEBUG: Sending WebSocket message: $message');
```

### 3. **ChatProvider Reply State**

```dart
print('DEBUG: Set reply to message: ${message.id} in conversation: $conversationId');
print('DEBUG: Cleared reply to message: ${removedMessage?.id} from conversation: $conversationId');
```

## 📋 Test Steps

### 1. **Test Reply State Management**

1. Mở app, vào chat
2. Nhấn reply button trên tin nhắn
3. Kiểm tra logs: `Set reply to message: xxx`
4. Kiểm tra preview có hiện không

### 2. **Test Send Message with Reply**

1. Sau khi set reply state
2. Gõ tin nhắn và gửi
3. Kiểm tra logs từ ChatProvider
4. Kiểm tra logs từ WebSocketService
5. Xem server có nhận `replyTo` field không

### 3. **Expected Debug Output**

```
DEBUG: Set reply to message: message_id_123 in conversation: conv_456
DEBUG: Auto-detected replyTo: message_id_123
DEBUG: Adding replyTo to message: message_id_123
DEBUG: Sending WebSocket message: {
  type: send_message,
  conversationId: conv_456,
  data: {
    content: reply_content,
    type: text,
    replyTo: message_id_123
  }
}
DEBUG: Cleared reply state for conversation: conv_456
```

## 🎯 Possible Issues

### **Issue 1: Reply State không được set**

- MessageReplyButton không gọi `setReplyToMessage`
- UI không trigger reply action

### **Issue 2: Reply State bị clear trước khi gửi**

- Có logic nào clear reply state trước `sendMessage`
- Multiple calls clearing state

### **Issue 3: Method call path sai**

- UI gọi sai method
- Parameter không được pass through

### **Issue 4: Timing issue**

- Reply state clear quá sớm
- WebSocket send trước khi detect reply

## 🔧 Fix Actions

### **Nếu Reply State không set:**

```dart
// Kiểm tra MessageReplyButton onPressed
chatProvider.setReplyToMessage(conversationId, message);
```

### **Nếu Reply State bị clear:**

```dart
// Ensure clear chỉ sau khi send success
if (finalReplyTo != null && isReplyingTo(conversationId)) {
  clearReplyToMessage(conversationId);
}
```

### **Nếu WebSocket không nhận replyTo:**

```dart
// Ensure WebSocketService check replyTo
if (replyTo != null) {
  data['replyTo'] = replyTo;
}
```

## 🚀 Test Plan

1. **Build app** với debug logs
2. **Test reply flow** step by step
3. **Check console logs** cho reply state
4. **Verify WebSocket payload** has replyTo
5. **Fix issues** found in logs

---

**Next: Run app và check debug logs để identify exact issue!** 🔍
