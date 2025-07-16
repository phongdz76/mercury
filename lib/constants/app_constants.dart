class ApiConstants {
  static const String baseUrl = 'http://192.168.1.4:3000';
  static const String wsUrl = 'ws://192.168.1.4:3000/chat/ws';

  // API Endpoints
  static const String authLogin = '/auth/login';
  static const String authRegister = '/auth/register';
  static const String conversations = '/conversations';
  static const String messages = '/messages';
  static const String users = '/users';

  // WebSocket Event Types
  static const String joinConversation = 'join_conversation';
  static const String leaveConversation = 'leave_conversation';
  static const String sendMessage = 'send_message';
  static const String typing = 'typing';
  static const String markRead = 'mark_read';
  static const String ping = 'ping';

  // Message Types
  static const String messageTypeText = 'TEXT';
  static const String messageTypeImage = 'IMAGE';
  static const String messageTypeFile = 'FILE';
  static const String messageTypeSystem = 'SYSTEM';

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
}
