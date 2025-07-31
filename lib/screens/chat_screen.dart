import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../models/conversation.dart';
import '../widgets/chat_app_bar.dart';
import '../widgets/chat_message_list.dart';
import '../widgets/chat_input_widget.dart';

class ChatScreen extends StatefulWidget {
  final Conversation conversation;

  const ChatScreen({super.key, required this.conversation});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  bool _isTyping = false;
  bool _isUploading = false;
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
    final chatProvider = context.read<ChatProvider>();

    // Check if there are pending attachments
    final hasPendingAttachments = chatProvider.hasPendingAttachments(
      widget.conversation.id,
    );

    if (content.isNotEmpty || hasPendingAttachments) {
      // Clear input immediately for better UX
      _messageController.clear();

      if (hasPendingAttachments) {
        // Send message with pending attachments (will handle reply automatically)
        chatProvider.sendMessageWithPendingAttachments(
          conversationId: widget.conversation.id,
          content: content,
        );
      } else {
        // Send normal text message (will handle reply automatically)
        chatProvider.sendMessage(
          conversationId: widget.conversation.id,
          content: content,
        );
      }

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

  void _scrollToMessage(String messageId) {
    final chatProvider = context.read<ChatProvider>();
    final messages = chatProvider.messages[widget.conversation.id] ?? [];
    final messageIndex = messages.indexWhere((m) => m.id == messageId);

    if (messageIndex != -1 && _scrollController.hasClients) {
      // Calculate approximate position (this is simplified)
      final position = messageIndex * 100.0; // Approximate message height
      _scrollController.animateTo(
        position,
        duration: const Duration(milliseconds: 500),
        curve: Curves.easeInOut,
      );
    }
  }

  void _setUploading(bool uploading) {
    setState(() {
      _isUploading = uploading;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: ChatAppBar(conversation: widget.conversation),
      body: Stack(
        children: [
          Column(
            children: [
              // Message List
              Expanded(
                child: ChatMessageList(
                  conversation: widget.conversation,
                  scrollController: _scrollController,
                  onRefresh: _refreshMessages,
                  onScrollToMessage: _scrollToMessage,
                ),
              ),

              // Typing indicator
              TypingIndicatorWidget(conversationId: widget.conversation.id),

              // Message input
              ChatInputWidget(
                messageController: _messageController,
                conversationId: widget.conversation.id,
                isUploading: _isUploading,
                onSendMessage: _sendMessage,
                onTyping: _onTyping,
                setUploading: _setUploading,
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
}
