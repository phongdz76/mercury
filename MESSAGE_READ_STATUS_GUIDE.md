# Message Read Status Implementation Guide

## Overview

This implementation provides comprehensive message read status functionality for the Mercury chat application. It handles real-time read receipt updates via WebSocket and provides methods for the UI to display and manage read status.

## Key Features

### 1. Real-time Read Status Updates

- Listens to WebSocket "read" events
- Updates message read receipts in real-time
- Automatically notifies UI components when read status changes

### 2. Message Read Status Checking

- Check if specific users have read a message
- Get comprehensive read receipt information
- Determine if read indicators should be shown

### 3. Conversation-level Read Status

- Get unread message counts per conversation
- Find latest unread messages
- Check if users have read the latest message

### 4. Bulk Read Operations

- Mark all messages in a conversation as read
- Auto-mark messages as read when they become visible
- Handle multiple messages at once

## Implementation Details

### Enhanced ChatProvider Methods

#### Read Status Checking

```dart
// Check if a specific user has read a message
bool isMessageReadByUser(String messageId, String userId, String conversationId)

// Check if current user has read a message
bool isMessageReadByCurrentUser(String messageId, String conversationId)

// Get all read receipts for a message
List<ReadReceipt> getMessageReadReceipts(String messageId, String conversationId)

// Check if read indicator should be shown for a message
bool shouldShowReadIndicator(String messageId, String conversationId)
```

#### Conversation Read Status

```dart
// Get unread messages count for a conversation
int getUnreadMessagesCount(String conversationId)

// Get latest unread message
Message? getLatestUnreadMessage(String conversationId)

// Get comprehensive read status info
Map<String, dynamic> getConversationReadStatus(String conversationId)

// Check if user has read the latest message
bool hasReadLatestMessage(String conversationId, String userId)
```

#### Bulk Read Operations

```dart
// Mark a single message as read
void markAsRead(String conversationId, String messageId)

// Mark multiple messages as read
void markMultipleMessagesAsRead(String conversationId, List<String> messageIds)

// Mark all messages in conversation as read
void markAllMessagesAsRead(String conversationId)

// Auto-mark visible messages as read
void markMessagesAsReadWhenVisible(String conversationId, List<String> visibleMessageIds)
```

#### UI Helper Methods

```dart
// Get formatted read status text
String getReadStatusText(String messageId, String conversationId)
```

### WebSocket Event Handling

The enhanced `_handleMessageRead` method processes incoming read events:

```dart
void _handleMessageRead(WebSocketEvent event) {
  final conversationId = event.conversationId;
  final messageId = event.data['messageId'] as String?;
  final userId = event.data['userId'] as String?;
  final readAt = event.data['readAt'] as String?;

  // Updates message read receipts and notifies UI
}
```

## Usage Examples

### 1. Displaying Read Status in Message Bubbles

```dart
// Use MessageReadStatusWidget to show read status
MessageReadStatusWidget(
  message: message,
  conversationId: conversationId,
)
```

### 2. Auto-marking Messages as Read

```dart
// In your chat list widget
void _onScroll() {
  final visibleMessageIds = _getVisibleMessageIds();
  chatProvider.markMessagesAsReadWhenVisible(
    conversationId,
    visibleMessageIds,
  );
}
```

### 3. Showing Unread Message Count

```dart
// In conversation list
Consumer<ChatProvider>(
  builder: (context, chatProvider, child) {
    final unreadCount = chatProvider.getUnreadMessagesCount(conversationId);
    return Badge(
      label: Text(unreadCount.toString()),
      child: ConversationListItem(...),
    );
  },
)
```

### 4. Mark All Messages as Read

```dart
// Add a button to mark all messages as read
ElevatedButton(
  onPressed: () {
    chatProvider.markAllMessagesAsRead(conversationId);
  },
  child: Text('Mark all as read'),
)
```

## WebSocket Integration

### Frontend WebSocket Handling (JavaScript equivalent)

```javascript
// Listen for read events
ws.onmessage = (event) => {
  const message = JSON.parse(event.data);

  switch (message.type) {
    case "read":
      handleMessageRead(message);
      break;
    // ... other cases
  }
};

// Handle read event
function handleMessageRead(event) {
  const { conversationId, data } = event;
  const { messageId, userId, readAt } = data;

  // Update UI to show message has been read
  updateMessageReadStatus(messageId, userId, readAt);
}

// Send mark as read request
function markMessageAsRead(messageId, conversationId) {
  ws.send(
    JSON.stringify({
      type: "mark_read",
      conversationId: conversationId,
      data: { messageId },
    })
  );
}
```

### Auto-marking Messages as Read

```javascript
// Auto-mark messages as read when they become visible
function handleMessageVisible(messageId, conversationId) {
  if (!isMessageRead(messageId)) {
    markMessageAsRead(messageId, conversationId);
  }
}

// Intersection Observer for detecting visible messages
const observer = new IntersectionObserver((entries) => {
  entries.forEach((entry) => {
    if (entry.isIntersecting) {
      const messageId = entry.target.dataset.messageId;
      const conversationId = entry.target.dataset.conversationId;
      handleMessageVisible(messageId, conversationId);
    }
  });
});
```

## UI Components

### 1. MessageReadStatusWidget

Shows read status indicators for messages sent by the current user:

- Single checkmark for sent messages
- Double checkmark for read messages
- Read count for group messages
- Tap to view detailed read receipts

### 2. AutoReadChatListExample

Demonstrates auto-marking messages as read when they become visible:

- Scroll-based read detection
- Unread message indicators
- Mark all as read functionality

### 3. Usage Examples

Complete examples showing integration with conversation lists and chat screens.

## Best Practices

### 1. Performance Optimization

- Use `markMessagesAsReadWhenVisible` sparingly (on scroll end)
- Cache read status to avoid repeated calculations
- Batch multiple read operations when possible

### 2. User Experience

- Show immediate feedback when marking messages as read
- Provide clear visual indicators for read/unread status
- Handle offline scenarios gracefully

### 3. Error Handling

- Wrap read operations in try-catch blocks
- Provide fallback UI states
- Handle WebSocket reconnection scenarios

### 4. Privacy Considerations

- Respect user privacy preferences
- Allow users to disable read receipts
- Handle read receipts appropriately in different conversation types

## Testing

### Unit Tests

```dart
// Test read status checking
test('should return true when message is read by user', () {
  // Test implementation
});

// Test conversation read status
test('should return correct unread count', () {
  // Test implementation
});
```

### Integration Tests

```dart
// Test WebSocket read event handling
testWidgets('should update UI when read event is received', (tester) async {
  // Test implementation
});
```

## Troubleshooting

### Common Issues

1. **Read status not updating**: Check WebSocket connection and event handling
2. **Performance issues**: Optimize visible message detection
3. **Incorrect unread counts**: Verify message filtering logic
4. **UI not refreshing**: Ensure `notifyListeners()` is called after updates

### Debug Tips

1. Add logging to WebSocket event handlers
2. Use Flutter Inspector to verify widget rebuilds
3. Monitor WebSocket message flow
4. Check message model data integrity

## Future Enhancements

1. **Delivery receipts**: Track when messages are delivered
2. **Typing indicators**: Enhanced typing status display
3. **Message reactions**: Read status for reactions
4. **Offline support**: Queue read operations for offline scenarios
5. **Push notifications**: Integration with read status
6. **Read receipt preferences**: User settings for read receipts

## Conclusion

This implementation provides a complete foundation for message read status functionality in the Mercury chat application. It handles real-time updates, provides comprehensive UI support, and follows Flutter best practices for state management and performance.

The modular design allows for easy extension and customization based on specific application requirements.
