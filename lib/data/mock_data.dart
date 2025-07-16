import '../models/conversation.dart';
import '../models/message.dart';
import '../models/user.dart';

class MockData {
  static final User currentUser = User(
    id: 'user_1',
    name: 'John Doe',
    email: 'john@example.com',
    isOnline: true,
  );

  static final List<User> users = [
    currentUser,
    User(
      id: 'user_2',
      name: 'Jane Smith',
      email: 'jane@example.com',
      isOnline: true,
    ),
    User(
      id: 'user_3',
      name: 'Bob Johnson',
      email: 'bob@example.com',
      isOnline: false,
      lastSeen: DateTime.now().subtract(const Duration(minutes: 30)),
    ),
  ];

  static final List<Conversation> conversations = [
    Conversation(
      id: 'conv_1',
      type: 'DIRECT',
      participants: ['user_1', 'user_2'],
      title: 'Jane Smith',
      createdBy: 'user_1',
      lastActivity: DateTime.now().subtract(const Duration(minutes: 5)),
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 1)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Conversation(
      id: 'conv_2',
      type: 'GROUP',
      participants: ['user_1', 'user_2', 'user_3'],
      title: 'Team Group',
      description: 'Team discussion group',
      createdBy: 'user_1',
      lastActivity: DateTime.now().subtract(const Duration(hours: 2)),
      isActive: true,
      createdAt: DateTime.now().subtract(const Duration(days: 3)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];

  static final List<Message> messages = [
    Message(
      id: 'msg_1',
      conversationId: 'conv_1',
      sender: 'user_2',
      content: 'Hello! How are you?',
      type: 'TEXT',
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 10)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 10)),
    ),
    Message(
      id: 'msg_2',
      conversationId: 'conv_1',
      sender: 'user_1',
      content: 'Hi Jane! I\'m doing well, thanks for asking.',
      type: 'TEXT',
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 8)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 8)),
    ),
    Message(
      id: 'msg_3',
      conversationId: 'conv_1',
      sender: 'user_2',
      content: 'That\'s great to hear! Are you free for a meeting later?',
      type: 'TEXT',
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now().subtract(const Duration(minutes: 5)),
      updatedAt: DateTime.now().subtract(const Duration(minutes: 5)),
    ),
    Message(
      id: 'msg_4',
      conversationId: 'conv_2',
      sender: 'user_3',
      content: 'Hey team! Can we schedule a meeting for tomorrow?',
      type: 'TEXT',
      isEdited: false,
      isDeleted: false,
      createdAt: DateTime.now().subtract(const Duration(hours: 2)),
      updatedAt: DateTime.now().subtract(const Duration(hours: 2)),
    ),
  ];
}
