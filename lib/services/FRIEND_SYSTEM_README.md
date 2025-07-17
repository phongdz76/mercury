# Friend System Implementation

This implementation provides a complete friend system for the Mercury Chat application based on the provided API documentation.

## Features Implemented

### 1. Core Models

- **Friendship Model** (`lib/models/friendship.dart`): Represents friendship relationships with status tracking
- **UserWithFriendship Model** (`lib/models/user_with_friendship.dart`): Extends User model with friendship status
- **FriendshipStatus Enum**: Defines status types (pending, accepted, rejected, blocked)

### 2. API Service

- **FriendService** (`lib/services/friend_service.dart`): Complete API integration with all friend endpoints
- **ApiService Updates**: Friend endpoints added to main API service for backward compatibility

### 3. State Management

- **FriendProvider** (`lib/providers/friend_provider.dart`): Comprehensive state management with WebSocket support
- Real-time updates for friend requests, accepts, rejects, and status changes
- Error handling and loading states

### 4. UI Components

- **FriendsScreen** (`lib/screens/friends_screen.dart`): Main friends interface with tabs
- **FriendSearchScreen** (`lib/screens/friend_search_screen.dart`): User search functionality
- **FriendRequestsScreen** (`lib/screens/friend_requests_screen.dart`): Manage friend requests
- **FriendSystemDemo** (`lib/screens/friend_system_demo.dart`): Demo screen showing all features

## API Endpoints Implemented

### Friend Management

- `GET /friends` - Get friends list
- `GET /friends/requests/pending` - Get pending requests
- `GET /friends/requests/sent` - Get sent requests
- `GET /friends/search?q=query` - Search users
- `POST /friends/requests` - Send friend request
- `PATCH /friends/requests/:id/accept` - Accept request
- `PATCH /friends/requests/:id/reject` - Reject request
- `DELETE /friends/requests/:id` - Cancel request
- `DELETE /friends/:id` - Remove friend
- `POST /friends/block` - Block user
- `DELETE /friends/block/:id` - Unblock user
- `GET /friends/blocked` - Get blocked users
- `GET /friends/status/:id` - Get friendship status

## WebSocket Integration

### Real-time Events Handled

- `friend_request` - New friend request received
- `friend_request_accepted` - Friend request accepted
- `friend_request_rejected` - Friend request rejected
- `friend_request_cancelled` - Friend request cancelled
- `friend_removed` - Friend removed
- `user_blocked` - User blocked
- `user_unblocked` - User unblocked

## Usage Examples

### Basic Usage

```dart
// Initialize the friend provider
final friendProvider = Provider.of<FriendProvider>(context, listen: false);

// Load friends
await friendProvider.loadFriends();

// Search for users
await friendProvider.searchUsers("john");

// Send friend request
await friendProvider.sendFriendRequest("user_id");

// Accept friend request
await friendProvider.acceptFriendRequest("request_id");
```

### Widget Integration

```dart
Consumer<FriendProvider>(
  builder: (context, friendProvider, child) {
    return ListView.builder(
      itemCount: friendProvider.friends.length,
      itemBuilder: (context, index) {
        final friend = friendProvider.friends[index];
        return ListTile(
          title: Text(friend.username),
          subtitle: Text(friend.email),
          trailing: friend.isOnline ? Icon(Icons.circle, color: Colors.green) : null,
        );
      },
    );
  },
)
```

## Navigation Integration

The friend system is integrated into the main app navigation:

- Friends button added to ConversationsScreen
- Complete tab-based navigation in FriendsScreen
- Search and requests accessible from main friends screen

## Error Handling

- Network errors are caught and displayed to users
- Loading states shown during API calls
- WebSocket connection errors handled gracefully
- User-friendly error messages throughout the UI

## Dependencies

The implementation uses these existing dependencies:

- `provider` - State management
- `http` - HTTP requests
- `web_socket_channel` - WebSocket communication
- `shared_preferences` - Token storage

## File Structure

```
lib/
├── models/
│   ├── friendship.dart
│   └── user_with_friendship.dart
├── services/
│   └── friend_service.dart
├── providers/
│   └── friend_provider.dart
├── screens/
│   ├── friends_screen.dart
│   ├── friend_search_screen.dart
│   ├── friend_requests_screen.dart
│   └── friend_system_demo.dart
└── main.dart (updated with FriendProvider)
```

## Testing

To test the friend system:

1. Run the app and navigate to the Friends screen
2. Use the search functionality to find users
3. Send friend requests and test acceptance/rejection
4. Test real-time updates with WebSocket
5. Use the demo screen to see all features in action

## Future Enhancements

- Friendship notifications
- Friend online status indicators
- Friend activity feed
- Group creation with friends
- Friend recommendations
- Import contacts integration

## Notes

- The implementation follows the exact API specification provided
- All endpoints are properly authenticated with JWT tokens
- WebSocket events are handled for real-time updates
- UI is responsive and includes loading/error states
- The code is well-structured and follows Flutter best practices
