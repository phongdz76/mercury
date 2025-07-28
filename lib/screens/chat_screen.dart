import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'package:file_picker/file_picker.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../models/message.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';
import '../widgets/user_avatar.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _picker = ImagePicker();
  bool _isTyping = false;
  bool _isUploading = false;
  int _previousMessageCount = 0;
  bool _showScrollToBottomButton = false;
  ChatProvider? _chatProvider;

  @override
  void initState() {
    super.initState();

    // Store reference to ChatProvider
    _chatProvider = context.read<ChatProvider>();

    // Add scroll listener to detect when user scrolls up
    _scrollController.addListener(_onScroll);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _chatProvider!.loadMessages(widget.conversation.id).then((_) {
        // Scroll to bottom after messages are loaded
        _scrollToBottom();
      });
    });
  }

  void _onScroll() {
    if (_scrollController.hasClients) {
      final threshold = _scrollController.position.maxScrollExtent - 100;
      final showButton = _scrollController.offset < threshold;

      if (showButton != _showScrollToBottomButton) {
        setState(() {
          _showScrollToBottomButton = showButton;
        });
      }
    }
  }

  @override
  void dispose() {
    // Leave conversation and clear messages when leaving chat screen (safely)
    _chatProvider?.leaveConversation(widget.conversation.id);
    _messageController.dispose();
    _scrollController.removeListener(_onScroll);
    _scrollController.dispose();
    super.dispose();
  }

  void _sendMessage() {
    final content = _messageController.text.trim();
    if (content.isNotEmpty) {
      context.read<ChatProvider>().sendMessage(
        conversationId: widget.conversation.id,
        content: content,
      );
      _messageController.clear();
      _scrollToBottom();
    }
  }

  Future<void> _refreshMessages() async {
    final chatProvider = context.read<ChatProvider>();
    await chatProvider.reloadMessages(widget.conversation.id);
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients && mounted) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  void _onTyping(String text) {
    final isCurrentlyTyping = text.isNotEmpty;
    if (_isTyping != isCurrentlyTyping) {
      _isTyping = isCurrentlyTyping;
      context.read<ChatProvider>().sendTyping(
        widget.conversation.id,
        _isTyping,
      );
    }
  }

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });

        final file = File(pickedFile.path);
        await context.read<ChatProvider>().sendMessageWithFile(
          conversationId: widget.conversation.id,
          file: file,
          type: ApiConstants.messageTypeImage,
          caption: null,
        );

        setState(() {
          _isUploading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickImageFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        setState(() {
          _isUploading = true;
        });

        final file = File(pickedFile.path);
        await context.read<ChatProvider>().sendMessageWithFile(
          conversationId: widget.conversation.id,
          file: file,
          type: ApiConstants.messageTypeImage,
          caption: null,
        );

        setState(() {
          _isUploading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send image: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickFile() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.any,
        allowMultiple: false,
      );

      if (result != null && result.files.isNotEmpty) {
        final file = File(result.files.single.path!);

        setState(() {
          _isUploading = true;
        });

        await context.read<ChatProvider>().sendMessageWithFile(
          conversationId: widget.conversation.id,
          file: file,
          type: ApiConstants.messageTypeFile,
          caption: null,
        );

        setState(() {
          _isUploading = false;
        });
        _scrollToBottom();
      }
    } catch (e) {
      setState(() {
        _isUploading = false;
      });
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to send file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                AppStrings.selectAttachment,
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const Icon(Icons.photo, color: Colors.blue),
                title: const Text(AppStrings.gallery),
                onTap: () {
                  Navigator.pop(context);
                  _pickImage();
                },
              ),
              ListTile(
                leading: const Icon(Icons.camera_alt, color: Colors.green),
                title: const Text(AppStrings.camera),
                onTap: () {
                  Navigator.pop(context);
                  _pickImageFromCamera();
                },
              ),
              ListTile(
                leading: const Icon(Icons.attach_file, color: Colors.orange),
                title: const Text(AppStrings.file),
                onTap: () {
                  Navigator.pop(context);
                  _pickFile();
                },
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Consumer<ChatProvider>(
          builder: (context, chatProvider, child) {
            // For direct chat, show the other participant's name and avatar
            if (widget.conversation.type ==
                ApiConstants.conversationTypeDirect) {
              final otherParticipantId = chatProvider.getOtherParticipant(
                widget.conversation,
              );
              final otherParticipantName = chatProvider.getUserDisplayName(
                otherParticipantId,
              );
              final otherParticipantAvatar = chatProvider.getUserAvatar(
                otherParticipantId,
              );
              final otherUser = chatProvider.userCache[otherParticipantId];

              return Row(
                children: [
                  UserAvatar(
                    avatarUrl: otherParticipantAvatar,
                    displayName: otherParticipantName,
                    size: 36,
                    showOnlineIndicator: true,
                    isOnline: otherUser?.isOnline ?? false,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          otherParticipantName,
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                          ),
                          overflow: TextOverflow.ellipsis,
                        ),
                        if (otherUser != null)
                          Text(
                            otherUser.isOnline
                                ? 'Online'
                                : otherUser.lastSeen != null
                                ? 'Last seen ${Utils.formatRelativeTime(otherUser.lastSeen!)}'
                                : 'Offline',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.white70,
                            ),
                          ),
                      ],
                    ),
                  ),
                ],
              );
            } else {
              // For group chat, show the conversation title and member count
              final memberCount = widget.conversation.participants.length;
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    widget.conversation.title ?? AppStrings.groupChat,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                    overflow: TextOverflow.ellipsis,
                  ),
                  Text(
                    '$memberCount members',
                    style: const TextStyle(fontSize: 12, color: Colors.white70),
                  ),
                ],
              );
            }
          },
        ),
        backgroundColor: Colors.blue,
        foregroundColor: Colors.white,
        actions: [
          Consumer<ChatProvider>(
            builder: (context, chatProvider, child) {
              return Icon(
                chatProvider.isConnected ? Icons.wifi : Icons.wifi_off,
                color: chatProvider.isConnected ? Colors.white : Colors.red,
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      body: Stack(
        children: [
          Column(
            children: [
              Expanded(
                child: Consumer<ChatProvider>(
                  builder: (context, chatProvider, child) {
                    final messages =
                        chatProvider.messages[widget.conversation.id] ?? [];

                    // Auto-scroll when new messages arrive (only if user is near bottom)
                    if (messages.length > _previousMessageCount) {
                      WidgetsBinding.instance.addPostFrameCallback((_) {
                        if (_scrollController.hasClients) {
                          final threshold =
                              _scrollController.position.maxScrollExtent - 200;
                          final isNearBottom =
                              _scrollController.offset >= threshold;

                          if (isNearBottom || _previousMessageCount == 0) {
                            _scrollToBottom();
                          }
                        }
                      });
                    }
                    _previousMessageCount = messages.length;

                    if (messages.isEmpty) {
                      return const Center(child: Text(AppStrings.noMessages));
                    }

                    return RefreshIndicator(
                      onRefresh: _refreshMessages,
                      child: ListView.builder(
                        controller: _scrollController,
                        padding: const EdgeInsets.all(8),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[index];
                          return _buildMessageItem(message, chatProvider);
                        },
                      ),
                    );
                  },
                ),
              ),

              // Typing indicator
              Consumer<ChatProvider>(
                builder: (context, chatProvider, child) {
                  final isTyping =
                      chatProvider.typingUsers[widget.conversation.id] ?? false;
                  return AnimatedContainer(
                    duration: const Duration(milliseconds: 200),
                    height: isTyping ? 40 : 0,
                    padding: const EdgeInsets.symmetric(horizontal: 16),
                    child: isTyping
                        ? const Row(
                            children: [
                              Icon(Icons.more_horiz, color: Colors.grey),
                              SizedBox(width: 8),
                              Text(
                                AppStrings.someonTyping,
                                style: TextStyle(color: Colors.grey),
                              ),
                            ],
                          )
                        : null,
                  );
                },
              ),

              // Message input
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.grey[100],
                  border: Border(top: BorderSide(color: Colors.grey[300]!)),
                ),
                child: Column(
                  children: [
                    // Upload progress indicator
                    if (_isUploading)
                      Container(
                        padding: const EdgeInsets.all(8),
                        child: Row(
                          children: [
                            const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            ),
                            const SizedBox(width: 12),
                            const Text('Uploading...'),
                          ],
                        ),
                      ),

                    // Message input row
                    Row(
                      children: [
                        IconButton(
                          onPressed: _isUploading
                              ? null
                              : _showAttachmentOptions,
                          icon: const Icon(Icons.attach_file),
                          color: Colors.blue,
                        ),
                        Expanded(
                          child: TextField(
                            controller: _messageController,
                            decoration: const InputDecoration(
                              hintText: AppStrings.typeMessage,
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 12,
                                vertical: 8,
                              ),
                            ),
                            onChanged: _onTyping,
                            onSubmitted: (_) => _sendMessage(),
                            maxLines: null,
                            enabled: !_isUploading,
                          ),
                        ),
                        const SizedBox(width: 8),
                        IconButton(
                          onPressed: _isUploading ? null : _sendMessage,
                          icon: const Icon(Icons.send),
                          color: Colors.blue,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),

          // Scroll to bottom button
          if (_showScrollToBottomButton)
            Positioned(
              right: 16,
              bottom: 100,
              child: FloatingActionButton.small(
                onPressed: _scrollToBottom,
                backgroundColor: Colors.blue,
                child: const Icon(
                  Icons.keyboard_arrow_down,
                  color: Colors.white,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMessageItem(Message message, ChatProvider chatProvider) {
    final isCurrentUser = message.sender == chatProvider.currentUser?.id;
    final isGroupChat = widget.conversation.type == 'group';
    final senderDisplayName = chatProvider.getUserDisplayName(message.sender);
    final senderAvatar = chatProvider.getUserAvatar(message.sender);

    // For group chat, show avatar for other users' messages
    if (isGroupChat && !isCurrentUser) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Avatar
            UserAvatar(
              avatarUrl: senderAvatar,
              displayName: senderDisplayName,
              size: 32,
            ),
            const SizedBox(width: 8),
            // Message bubble
            Flexible(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Sender name
                  Padding(
                    padding: const EdgeInsets.only(left: 12, bottom: 2),
                    child: Text(
                      senderDisplayName,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 12,
                        color: UserAvatar.getColorForName(senderDisplayName),
                      ),
                    ),
                  ),
                  // Message content
                  Container(
                    padding: const EdgeInsets.all(12),
                    constraints: BoxConstraints(
                      maxWidth: MediaQuery.of(context).size.width * 0.7,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.grey[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        _buildMessageContent(message, isCurrentUser),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Utils.formatTime(message.createdAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            if (message.isEdited) ...[
                              const SizedBox(width: 4),
                              const Icon(
                                Icons.edit,
                                size: 12,
                                color: Colors.grey,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      );
    } else {
      // For direct chat or current user's messages in group chat
      return Align(
        alignment: isCurrentUser ? Alignment.centerRight : Alignment.centerLeft,
        child: Container(
          margin: const EdgeInsets.symmetric(vertical: 4),
          padding: const EdgeInsets.all(12),
          constraints: BoxConstraints(
            maxWidth: MediaQuery.of(context).size.width * 0.7,
          ),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue : Colors.grey[200],
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show sender name for direct chat when not current user
              if (!isCurrentUser && !isGroupChat)
                Text(
                  senderDisplayName,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                    color: Colors.grey,
                  ),
                ),

              // Message content based on type
              _buildMessageContent(message, isCurrentUser),

              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Utils.formatTime(message.createdAt),
                    style: TextStyle(
                      fontSize: 10,
                      color: isCurrentUser ? Colors.white70 : Colors.grey,
                    ),
                  ),

                  if (message.isEdited) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit,
                      size: 12,
                      color: isCurrentUser ? Colors.white70 : Colors.grey,
                    ),
                  ],

                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    Icon(Icons.check, size: 12, color: Colors.white70),
                  ],
                ],
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildMessageContent(Message message, bool isCurrentUser) {
    switch (message.type) {
      case ApiConstants.messageTypeImage:
        return _buildImageMessage(message, isCurrentUser);
      case ApiConstants.messageTypeFile:
        return _buildFileMessage(message, isCurrentUser);
      case ApiConstants.messageTypeText:
      default:
        return _buildTextMessage(message, isCurrentUser);
    }
  }

  Widget _buildTextMessage(Message message, bool isCurrentUser) {
    return Text(
      message.content,
      style: TextStyle(color: isCurrentUser ? Colors.white : Colors.black),
    );
  }

  Widget _buildImageMessage(Message message, bool isCurrentUser) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachments != null && message.attachments!.isNotEmpty)
          ClipRRect(
            borderRadius: BorderRadius.circular(8),
            child: Image.network(
              ApiConstants.baseUrl +
                  ApiConstants.attachments +
                  '/' +
                  message.attachments!.first.url,
              width: double.infinity,
              fit: BoxFit.cover,
              loadingBuilder: (context, child, loadingProgress) {
                if (loadingProgress == null) return child;
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: CircularProgressIndicator(
                    value: loadingProgress.expectedTotalBytes != null
                        ? loadingProgress.cumulativeBytesLoaded /
                              loadingProgress.expectedTotalBytes!
                        : null,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return Container(
                  height: 200,
                  alignment: Alignment.center,
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.error,
                        color: isCurrentUser ? Colors.white70 : Colors.grey,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Failed to load image',
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white70 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.content,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildFileMessage(Message message, bool isCurrentUser) {
    final attachment = message.attachments?.first;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: isCurrentUser ? Colors.blue.shade700 : Colors.grey[300],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: [
              Icon(
                _getFileIcon(attachment?.name ?? ''),
                color: isCurrentUser ? Colors.white : Colors.black54,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      attachment?.name ?? 'Unknown file',
                      style: TextStyle(
                        color: isCurrentUser ? Colors.white : Colors.black,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    if (attachment?.size != null)
                      Text(
                        _formatFileSize(attachment!.size),
                        style: TextStyle(
                          color: isCurrentUser ? Colors.white70 : Colors.grey,
                          fontSize: 12,
                        ),
                      ),
                  ],
                ),
              ),
              Icon(
                Icons.download,
                color: isCurrentUser ? Colors.white : Colors.black54,
              ),
            ],
          ),
        ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.content,
              style: TextStyle(
                color: isCurrentUser ? Colors.white : Colors.black,
              ),
            ),
          ),
      ],
    );
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf;
      case 'doc':
      case 'docx':
        return Icons.description;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow;
      case 'txt':
        return Icons.text_snippet;
      case 'zip':
      case 'rar':
        return Icons.archive;
      case 'mp3':
      case 'wav':
        return Icons.audio_file;
      case 'mp4':
      case 'mov':
        return Icons.video_file;
      default:
        return Icons.insert_drive_file;
    }
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
