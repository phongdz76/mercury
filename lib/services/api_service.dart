// Main API service that exports all individual services for backward compatibility
export 'auth_service.dart';
export 'base_service.dart';
export 'conversation_service.dart';
export 'friend_service.dart';
export 'message_service.dart';
export 'payment_service.dart';
export 'upload_service.dart';
export 'user_service.dart';

// Legacy API service class - kept for backward compatibility
// Consider migrating to individual service classes
import 'dart:io';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';
import '../models/friend_user.dart';
import '../models/friendship.dart';
import '../models/user_with_friendship.dart';
import '../constants/app_constants.dart';
import 'auth_service.dart';
import 'conversation_service.dart';
import 'friend_service.dart';
import 'message_service.dart';
import 'upload_service.dart';
import 'user_service.dart';

class ApiService {
  static const String baseUrl = ApiConstants.baseUrl;

  // Token management - use BaseService instead
  static Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('jwt_token');
  }

  static Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('jwt_token', token);
  }

  static Future<void> clearToken() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('jwt_token');
  }

  static Future<Map<String, String>> getHeaders() async {
    final token = await getToken();
    return {
      'Content-Type': 'application/json',
      if (token != null) 'Authorization': 'Bearer $token',
    };
  }

  // Auth endpoints - use AuthService instead
  static Future<Map<String, dynamic>> login(String email, String password) =>
      AuthService.login(email, password);

  static Future<Map<String, dynamic>> register(
    String username,
    String email,
    String password,
  ) => AuthService.register(username, email, password);

  // Conversation endpoints - use ConversationService instead
  static Future<List<Conversation>> getConversations() =>
      ConversationService.getConversations();

  static Future<Conversation> getConversation(String id) =>
      ConversationService.getConversation(id);

  static Future<Conversation> createConversation({
    required String type,
    required List<String> participants,
    String? title,
    String? description,
  }) => ConversationService.createConversation(
    type: type,
    participants: participants,
    title: title,
    description: description,
  );

  // Message endpoints - use MessageService instead
  static Future<List<Message>> getMessages(
    String conversationId, {
    int page = 1,
    int limit = 50,
  }) => MessageService.getMessages(conversationId, page: page, limit: limit);

  static Future<Message> sendMessage({
    required String conversationId,
    required String content,
    required String type,
    String? replyTo,
  }) => MessageService.sendMessage(
    conversationId: conversationId,
    content: content,
    type: type,
    replyTo: replyTo,
  );

  static Future<Message> editMessage(String messageId, String content) =>
      MessageService.editMessage(messageId, content);

  static Future<void> deleteMessage(String messageId) =>
      MessageService.deleteMessage(messageId);

  static Future<void> markAsRead(String messageId) =>
      MessageService.markAsRead(messageId);

  // User endpoints - use UserService instead
  static Future<User> getCurrentUser() => UserService.getCurrentUser();

  static String getUserAvatarUrl(String userId) =>
      UserService.getUserAvatarUrl(userId);

  static Future<User> getUserById(String userId) =>
      UserService.getUserById(userId);

  static Future<User> getProfile() => UserService.getProfile();

  static Future<User> updateProfile({
    required String username,
    required String email,
    String? fullName,
    String? avatar,
  }) => UserService.updateProfile(
    username: username,
    email: email,
    fullName: fullName,
    avatar: avatar,
  );

  static Future<void> changePassword({
    required String currentPassword,
    required String newPassword,
    required String confirmPassword,
  }) => UserService.changePassword(
    currentPassword: currentPassword,
    newPassword: newPassword,
    confirmPassword: confirmPassword,
  );

  // Upload endpoints - use UploadService instead
  static Future<String> uploadAvatar(File imageFile) =>
      UploadService.uploadAvatar(imageFile);

  static String getMimeType(String filePath) =>
      UploadService.getMimeType(filePath);

  static Future<Map<String, dynamic>> uploadMessageFile(
    File file,
    String conversationId,
  ) => UploadService.uploadMessageFile(file, conversationId);

  // Send message with file attachment - use MessageService instead
  static Future<Message> sendMessageWithFile({
    required String conversationId,
    required String content,
    required String type,
    required String fileUrl,
    required String fileName,
    required String mimeType,
    required int fileSize,
    String? replyTo,
  }) => MessageService.sendMessageWithFile(
    conversationId: conversationId,
    content: content,
    type: type,
    fileUrl: fileUrl,
    fileName: fileName,
    mimeType: mimeType,
    fileSize: fileSize,
    replyTo: replyTo,
  );

  // Friend endpoints - use FriendService instead
  static Future<List<FriendUser>> getFriends() => FriendService.getFriends();

  static Future<List<Friendship>> getPendingRequests() =>
      FriendService.getPendingRequests();

  static Future<List<Friendship>> getSentRequests() =>
      FriendService.getSentRequests();

  static Future<List<UserWithFriendship>> searchUsers(String query) =>
      FriendService.searchUsers(query);

  static Future<Friendship> sendFriendRequest(String userId) =>
      FriendService.sendFriendRequest(userId);

  static Future<Friendship> acceptFriendRequest(String requestId) =>
      FriendService.acceptFriendRequest(requestId);

  static Future<Friendship> rejectFriendRequest(String requestId) =>
      FriendService.rejectFriendRequest(requestId);

  static Future<void> cancelFriendRequest(String requestId) =>
      FriendService.cancelFriendRequest(requestId);

  static Future<void> removeFriend(String friendshipId) =>
      FriendService.removeFriend(friendshipId);

  static Future<Friendship> blockUser(String userId) =>
      FriendService.blockUser(userId);

  static Future<void> unblockUser(String userId) =>
      FriendService.unblockUser(userId);

  static Future<List<User>> getBlockedUsers() =>
      FriendService.getBlockedUsers();

  static Future<FriendshipStatus?> getFriendshipStatus(String userId) =>
      FriendService.getFriendshipStatus(userId);
}
