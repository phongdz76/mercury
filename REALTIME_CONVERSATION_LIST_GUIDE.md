# Real-time Conversation List Implementation Guide

## Tổng quan

Hệ thống real-time conversation list đã được nâng cấp để hỗ trợ các tính năng sau:

### ✨ Tính năng mới

1. **Real-time Unread Count**: Hiển thị số tin nhắn chưa đọc real-time
2. **Conversation Status**: Mute/Unmute, Archive/Unarchive conversations
3. **Enhanced UI**: Improved visual indicators và user experience
4. **Smart Sorting**: Conversations được sắp xếp theo last activity
5. **Connection Management**: Auto subscribe/unsubscribe to WebSocket events
6. **Pull-to-Refresh**: Manual refresh với real-time sync

### 🔧 Cải tiến kỹ thuật

#### 1. Enhanced Conversation Model

```dart
class Conversation {
  // ... existing fields ...
  final int unreadCount;
  final bool isMuted;
  final bool isArchived;
  final String? lastMessageType;
  final String? lastMessageSender;

  // Helper method for easy updates
  Conversation copyWith({...}) { ... }
}
```

#### 2. Extended WebSocket Service

```dart
class WebSocketService {
  // New methods for conversation list management
  void subscribeToConversationList();
  void unsubscribeFromConversationList();
  void refreshConversationList();
  void markConversationAsRead(String conversationId);
  void archiveConversation(String conversationId, bool archive);
  void muteConversation(String conversationId, bool mute);
}
```

#### 3. Enhanced ChatProvider

```dart
class ChatProvider {
  // New conversation management methods
  void markConversationAsRead(String conversationId);
  void muteConversation(String conversationId, bool mute);
  void archiveConversation(String conversationId, bool archive);
  int getTotalUnreadCount();
  List<Conversation> getActiveConversations();
  List<Conversation> getArchivedConversations();

  // New WebSocket event handlers
  void _handleConversationListUpdated(WebSocketEvent event);
  void _handleConversationReadStatusChanged(WebSocketEvent event);
  void _handleConversationMuted(WebSocketEvent event);
  void _handleConversationArchived(WebSocketEvent event);
  void _handleUnreadCountUpdated(WebSocketEvent event);
}
```

## 📱 UI Components

### 1. ConversationsScreenEnhanced

```dart
// Enhanced conversation screen with real-time features
class ConversationsScreenEnhanced extends StatefulWidget {
  // Features:
  // - Real-time unread count in app bar
  // - Auto subscribe/unsubscribe to WebSocket events
  // - App lifecycle management
  // - Enhanced conversation options
}
```

### 2. RealtimeConversationList Widget

```dart
// Reusable widget for displaying conversation lists
class RealtimeConversationList extends StatefulWidget {
  final bool showArchived;
  final VoidCallback? onRefresh;

  // Features:
  // - Separate active and archived conversations
  // - Real-time updates without rebuilding entire list
  // - Smart loading states
  // - Enhanced error handling
}
```

## 🔄 WebSocket Events

### Incoming Events (from server)

```javascript
// New message -> updates conversation last message and unread count
{
  type: "message",
  conversationId: "conv_123",
  data: { /* message data */ }
}

// Conversation list update
{
  type: "conversation_list_updated",
  data: {
    conversation: { /* updated conversation */ }
  }
}

// Read status update
{
  type: "conversation_read_status_changed",
  conversationId: "conv_123",
  data: {
    unreadCount: 0
  }
}

// Mute status update
{
  type: "conversation_muted",
  conversationId: "conv_123",
  data: {
    isMuted: true
  }
}

// Archive status update
{
  type: "conversation_archived",
  conversationId: "conv_123",
  data: {
    isArchived: true
  }
}

// Unread count update
{
  type: "unread_count_updated",
  conversationId: "conv_123",
  data: {
    unreadCount: 5
  }
}
```

### Outgoing Events (to server)

```javascript
// Subscribe to conversation list updates
{
  type: "subscribe_conversation_list",
  data: {}
}

// Mark conversation as read
{
  type: "mark_conversation_read",
  conversationId: "conv_123",
  data: {}
}

// Mute conversation
{
  type: "mute_conversation",
  conversationId: "conv_123",
  data: {
    mute: true
  }
}

// Archive conversation
{
  type: "archive_conversation",
  conversationId: "conv_123",
  data: {
    archive: true
  }
}
```

## 🎯 Usage

### Basic Usage

```dart
// In your main conversations screen
class ConversationsScreen extends StatefulWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            final unreadCount = chatProvider.getTotalUnreadCount();
            return Row(
              children: [
                Text('Conversations'),
                if (unreadCount > 0)
                  UnreadBadge(count: unreadCount),
              ],
            );
          },
        ),
      ),
      body: RealtimeConversationList(),
    );
  }
}
```

### Archived Conversations

```dart
// Show archived conversations
RealtimeConversationList(
  showArchived: true,
  onRefresh: () {
    // Custom refresh logic
  },
)
```

### Manual Conversation Management

```dart
final chatProvider = context.read<ChatProvider>();

// Mark as read
chatProvider.markConversationAsRead(conversationId);

// Mute/unmute
chatProvider.muteConversation(conversationId, true);

// Archive/unarchive
chatProvider.archiveConversation(conversationId, true);

// Get statistics
final totalUnread = chatProvider.getTotalUnreadCount();
final activeConversations = chatProvider.getActiveConversations();
final archivedConversations = chatProvider.getArchivedConversations();
```

## 🎨 Visual Features

### 1. Unread Count Badges

- Red badges for unread conversations
- Grey badges for muted conversations
- "99+" for counts over 99

### 2. Visual Indicators

- 🔇 Muted icon for muted conversations
- 🟢 Online indicator for active users
- 📅 Formatted timestamps
- 📱 Different avatars for direct vs group chats

### 3. Enhanced Conversation Items

- Bold text for unread conversations
- Subtle background color for unread items
- Long press for context menu
- Tap to mark as read automatically

## 🔧 Implementation Details

### 1. App Lifecycle Management

```dart
class _ConversationsScreenState extends State<ConversationsScreen>
    with WidgetsBindingObserver {

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    final chatProvider = context.read<ChatProvider>();
    switch (state) {
      case AppLifecycleState.resumed:
        chatProvider.subscribeToConversationListUpdates();
        break;
      case AppLifecycleState.paused:
        chatProvider.unsubscribeFromConversationListUpdates();
        break;
    }
  }
}
```

### 2. Memory Management

```dart
@override
void dispose() {
  // Unsubscribe from WebSocket events
  context.read<ChatProvider>().unsubscribeFromConversationListUpdates();
  super.dispose();
}
```

### 3. Error Handling

```dart
// Robust error handling with retry functionality
if (chatProvider.error != null) {
  return ErrorWidget(
    error: chatProvider.error,
    onRetry: () {
      chatProvider.clearError();
      chatProvider.initialize();
      chatProvider.subscribeToConversationListUpdates();
    },
  );
}
```

## 🚀 Performance Optimizations

### 1. Efficient List Updates

- Only rebuild affected conversation items
- Use `Consumer` instead of full screen rebuilds
- Implement `AutomaticKeepAliveClientMixin` for list state

### 2. Smart Caching

- User avatar caching
- Conversation data caching
- Optimistic UI updates

### 3. WebSocket Optimization

- Subscribe only when screen is active
- Unsubscribe when app is in background
- Automatic reconnection handling

## 🧪 Testing

### Manual Testing Scenarios

1. **Real-time Updates**

   - Send message from another device
   - Verify conversation moves to top
   - Check unread count updates

2. **Conversation Management**

   - Mute conversation → verify muted icon
   - Archive conversation → verify removal from main list
   - Mark as read → verify unread count clears

3. **App Lifecycle**
   - Background app → verify WebSocket unsubscribe
   - Resume app → verify WebSocket resubscribe
   - Network loss → verify reconnection

### Unit Tests

```dart
testWidgets('should display unread count badge', (tester) async {
  // Test unread count display
});

testWidgets('should mark conversation as read on tap', (tester) async {
  // Test read status update
});

testWidgets('should show conversation options on long press', (tester) async {
  // Test context menu
});
```

## 📋 Backend Requirements

### WebSocket Events to Implement

1. **conversation_list_updated**: When any conversation changes
2. **conversation_read_status_changed**: When read status changes
3. **conversation_muted**: When mute status changes
4. **conversation_archived**: When archive status changes
5. **unread_count_updated**: When unread count changes

### API Endpoints

```
PUT /conversations/{id}/read - Mark conversation as read
PUT /conversations/{id}/mute - Mute/unmute conversation
PUT /conversations/{id}/archive - Archive/unarchive conversation
GET /conversations?archived=true - Get archived conversations
```

## 🔮 Future Enhancements

1. **Push Notifications**: Integration with FCM for background updates
2. **Message Previews**: Rich message previews in conversation list
3. **Pinned Conversations**: Pin important conversations to top
4. **Search & Filter**: Search conversations and filter by status
5. **Bulk Operations**: Select multiple conversations for bulk actions
6. **Custom Notifications**: Per-conversation notification settings

## 🛠️ Troubleshooting

### Common Issues

1. **Unread count not updating**

   - Check WebSocket connection
   - Verify event handlers are registered
   - Check server-side event emission

2. **Conversations not sorting properly**

   - Verify `_sortConversations()` is called after updates
   - Check `lastActivity` timestamp updates

3. **Memory leaks**
   - Ensure WebSocket subscription cleanup
   - Verify `dispose()` methods are called
   - Check for circular references

### Debug Tools

```dart
// Enable WebSocket debugging
class WebSocketService {
  void _send(Map<String, dynamic> message) {
    if (kDebugMode) {
      print('WebSocket Send: ${jsonEncode(message)}');
    }
    // ... send logic
  }
}

// Enable conversation state debugging
class ChatProvider {
  void _handleWebSocketEvent(WebSocketEvent event) {
    if (kDebugMode) {
      print('WebSocket Event: ${event.type} - ${event.data}');
    }
    // ... handle event
  }
}
```

Với implementation này, bạn sẽ có một hệ thống conversation list real-time hoàn chỉnh với các tính năng hiện đại và user experience tốt.
