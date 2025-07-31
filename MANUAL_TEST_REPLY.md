# 🧪 MANUAL TEST: Reply WebSocket Integration

## 📋 Test Checklist

### ✅ **Test 1: Reply Button Visibility**

- [ ] Mở chat screen
- [ ] Kiểm tra mỗi tin nhắn có reply button (↩️) không
- [ ] Cả tin nhắn của mình và người khác đều có reply button

### ✅ **Test 2: Set Reply State**

- [ ] Nhấn reply button trên tin nhắn
- [ ] Kiểm tra console log: `DEBUG: Reply button pressed for message: xxx`
- [ ] Kiểm tra console log: `DEBUG: Set reply to message: xxx in conversation: yyy`
- [ ] Kiểm tra reply preview xuất hiện phía trên input

### ✅ **Test 3: Reply Preview Display**

- [ ] Reply preview có hiển thị đúng tên người gửi
- [ ] Reply preview có hiển thị nội dung tin nhắn cắt ngắn
- [ ] Clear button (❌) có xuất hiện trên AppBar

### ✅ **Test 4: Send Reply Message**

- [ ] Gõ tin nhắn reply
- [ ] Nhấn Send button
- [ ] Kiểm tra console logs:
  ```
  DEBUG: Auto-detected replyTo: message_id
  DEBUG: Adding replyTo to message: message_id
  DEBUG: Sending WebSocket message: {...}
  DEBUG: Cleared reply state for conversation: xxx
  ```

### ✅ **Test 5: WebSocket Payload Verification**

- [ ] Kiểm tra server logs có nhận được:
  ```json
  {
    "type": "send_message",
    "conversationId": "xxx",
    "data": {
      "content": "reply content",
      "type": "text",
      "replyTo": "original_message_id" // ← FIELD NÀY PHẢI CÓ
    }
  }
  ```

### ✅ **Test 6: Reply State Management**

- [ ] Sau khi gửi tin nhắn, reply preview biến mất
- [ ] Clear button trên AppBar biến mất
- [ ] Console log: `DEBUG: Cleared reply state for conversation: xxx`

### ✅ **Test 7: Reply Context Display**

- [ ] Tin nhắn reply hiển thị với reply context
- [ ] Reply context có viền xanh và icon ↩️
- [ ] Tap vào reply context để scroll đến tin nhắn gốc

## 🚨 Common Issues & Solutions

### **Issue: Reply button không hiện**

**Fix:** Kiểm tra MessageReplyButton logic trong `_buildMessageItem`

### **Issue: Reply preview không hiện**

**Fix:** Kiểm tra ReplyPreviewWidget và `isReplyingTo()` method

### **Issue: WebSocket thiếu replyTo**

**Fix:** Kiểm tra `sendMessage()` có auto-detect reply state đúng

### **Issue: Reply state không clear**

**Fix:** Kiểm tra logic clear trong `sendMessage()` method

## 🎯 Expected Flow

```
1. User nhấn Reply button
   ↓
2. setReplyToMessage() được gọi
   ↓
3. Reply preview xuất hiện
   ↓
4. User gõ tin nhắn và nhấn Send
   ↓
5. sendMessage() auto-detect reply state
   ↓
6. WebSocketService.sendMessage() với replyTo field
   ↓
7. Server nhận request với replyTo
   ↓
8. clearReplyToMessage() được gọi
   ↓
9. Reply preview biến mất
```

## 📊 Debug Commands

### **Check Reply State:**

```dart
print('Reply state: ${chatProvider.isReplyingTo(conversationId)}');
print('Reply message: ${chatProvider.getReplyToMessage(conversationId)?.id}');
```

### **Check WebSocket Connection:**

```dart
print('WebSocket connected: ${chatProvider.isConnected}');
```

### **Manual Test Reply:**

```dart
// Set reply manually
chatProvider.setReplyToMessage(conversationId, someMessage);

// Check state
print('Is replying: ${chatProvider.isReplyingTo(conversationId)}');

// Send message
chatProvider.sendMessage(
  conversationId: conversationId,
  content: 'test reply'
);
```

---

**🔥 CRITICAL: Kiểm tra server logs để confirm WebSocket có nhận replyTo field!**
