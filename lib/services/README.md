# Services Structure

This directory contains the API services organized by feature. The original `ApiService` class has been refactored into smaller, focused service classes.

## Service Classes

### BaseService

- **File**: `base_service.dart`
- **Purpose**: Common functionality used by all services
- **Features**:
  - Token management (get, save, clear)
  - HTTP headers generation
  - Response handling utilities

### AuthService

- **File**: `auth_service.dart`
- **Purpose**: Authentication-related operations
- **Features**:
  - User login
  - User registration
  - Token management
  - Logout functionality

### ConversationService

- **File**: `conversation_service.dart`
- **Purpose**: Conversation management
- **Features**:
  - Get conversations list
  - Get specific conversation
  - Create new conversation

### MessageService

- **File**: `message_service.dart`
- **Purpose**: Message operations
- **Features**:
  - Get messages from conversation
  - Send text messages
  - Send messages with file attachments
  - Edit messages
  - Delete messages
  - Mark messages as read

### UserService

- **File**: `user_service.dart`
- **Purpose**: User profile and user-related operations
- **Features**:
  - Get current user
  - Get user by ID
  - Get user profile
  - Update user profile
  - Change password
  - Get user avatar URL

### UploadService

- **File**: `upload_service.dart`
- **Purpose**: File upload functionality
- **Features**:
  - Upload user avatar
  - Upload message attachments
  - MIME type detection
  - File validation

## Migration Guide

### From Old ApiService to New Structure

**Old way:**

```dart
import '../services/api_service.dart';

// Usage
final user = await ApiService.getCurrentUser();
await ApiService.login(email, password);
```

**New way (recommended):**

```dart
import '../services/user_service.dart';
import '../services/auth_service.dart';

// Usage
final user = await UserService.getCurrentUser();
await AuthService.login(email, password);
```

### Backward Compatibility

The original `ApiService` class is still available for backward compatibility, but it's now deprecated. It delegates all calls to the appropriate service classes.

To maintain backward compatibility while migrating:

1. **Immediate**: Continue using `ApiService` as before
2. **Gradual migration**: Replace `ApiService` calls with specific service classes
3. **Final step**: Remove `ApiService` imports and use only specific services

## Benefits of New Structure

1. **Separation of Concerns**: Each service handles a specific domain
2. **Better Maintainability**: Easier to locate and modify specific functionality
3. **Reduced Dependencies**: Import only what you need
4. **Better Testing**: Easier to mock and test individual services
5. **Code Reusability**: Services can be used independently
6. **Cleaner Architecture**: More organized and scalable codebase

## Usage Examples

### Authentication

```dart
import '../services/auth_service.dart';

// Login
final userData = await AuthService.login(email, password);

// Register
final userData = await AuthService.register(username, email, password);

// Logout
await AuthService.logout();
```

### Conversations

```dart
import '../services/conversation_service.dart';

// Get all conversations
final conversations = await ConversationService.getConversations();

// Get specific conversation
final conversation = await ConversationService.getConversation(id);

// Create new conversation
final newConversation = await ConversationService.createConversation(
  type: 'private',
  participants: [userId1, userId2],
  title: 'Chat Title',
);
```

### Messages

```dart
import '../services/message_service.dart';

// Get messages
final messages = await MessageService.getMessages(conversationId);

// Send message
final message = await MessageService.sendMessage(
  conversationId: conversationId,
  content: 'Hello!',
  type: 'text',
);

// Send message with file
final message = await MessageService.sendMessageWithFile(
  conversationId: conversationId,
  content: 'Check this file',
  type: 'file',
  fileUrl: fileUrl,
  fileName: 'document.pdf',
  mimeType: 'application/pdf',
  fileSize: 1024,
);
```

### User Management

```dart
import '../services/user_service.dart';

// Get current user
final user = await UserService.getCurrentUser();

// Update profile
final updatedUser = await UserService.updateProfile(
  username: 'newusername',
  email: 'new@email.com',
  fullName: 'New Full Name',
);

// Change password
await UserService.changePassword(
  currentPassword: 'oldpass',
  newPassword: 'newpass',
  confirmPassword: 'newpass',
);
```

### File Upload

```dart
import '../services/upload_service.dart';

// Upload avatar
final avatarUrl = await UploadService.uploadAvatar(imageFile);

// Upload file for message
final fileData = await UploadService.uploadMessageFile(file, conversationId);
```
