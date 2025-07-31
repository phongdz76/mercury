class ApiConstants {
  static const String baseUrl = 'https://api.meowsical.me';
  static const String wsUrl = 'wss://api.meowsical.me/chat/ws';

  // API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String users = '/users';
  static const String profile = '/me';
  static const String changePassword = '/me/password';
  static const String userAvatar = '/users'; // For /users/:id/avatar
  static const String payments = '/payments';
  static const String attachments =
      '/uploads/attachments'; // For /uploads/attachments/:filename

  // WebSocket Event Types
  static const String joinConversation = 'join_conversation';
  static const String leaveConversation = 'leave_conversation';
  static const String sendMessage = 'send_message';
  static const String typing = 'typing';
  static const String markRead = 'mark_read';
  static const String ping = 'ping';

  // Message Types
  static const String messageTypeText = 'text';
  static const String messageTypeImage = 'image';
  static const String messageTypeFile = 'file';
  static const String messageTypeVideo = 'video';
  static const String messageTypeAudio = 'audio';
  static const String messageTypeDocument = 'document';
  static const String messageTypeSystem = 'system';

  // Conversation Types
  static const String conversationTypeDirect =
      'direct'; // Changed from 'DIRECT'
  static const String conversationTypeGroup = 'group'; // Changed from 'GROUP'
}

class AppStrings {
  static const String appName = 'Mercury Chat';
  static const String login = 'Login';
  static const String register = 'Register';
  static const String email = 'Email';
  static const String password = 'Password';
  static const String name = 'Name';
  static const String conversations = 'Conversations';
  static const String typeMessage = 'Type a message...';
  static const String send = 'Send';
  static const String connected = 'Connected';
  static const String disconnected = 'Disconnected';
  static const String noConversations =
      'No conversations yet. Create one to start chatting!';
  static const String noMessages = 'No messages yet. Start the conversation!';
  static const String createConversation = 'Create Conversation';
  static const String directChat = 'Direct Chat';
  static const String groupChat = 'Group Chat';
  static const String someonTyping = 'Someone is typing...';

  // Profile strings
  static const String profile = 'Profile';
  static const String editProfile = 'Edit Profile';
  static const String changePassword = 'Change Password';
  static const String username = 'Username';
  static const String fullName = 'Full Name';
  static const String currentPassword = 'Current Password';
  static const String newPassword = 'New Password';
  static const String confirmPassword = 'Confirm Password';
  static const String save = 'Save';
  static const String cancel = 'Cancel';
  static const String profileUpdated = 'Profile updated successfully';
  static const String passwordChanged = 'Password changed successfully';

  // File upload strings
  static const String selectAttachment = 'Select Attachment';
  static const String gallery = 'Gallery';
  static const String camera = 'Camera';
  static const String video = 'Video';
  static const String recordVideo = 'Record Video';
  static const String file = 'File';
  static const String uploadingFile = 'Uploading file...';
  static const String uploadingImage = 'Uploading image...';
  static const String uploadingVideo = 'Uploading video...';
  static const String failedToUpload = 'Failed to upload';
}
