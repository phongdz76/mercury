import 'package:flutter/material.dart';
import '../models/message.dart';
import '../models/conversation.dart';
import '../providers/chat_provider.dart';
import '../constants/app_constants.dart';
import '../utils/utils.dart';
import 'user_avatar.dart';
import 'message_reply_widgets.dart';
import 'image_viewer_widget.dart';
import 'video_player_widget.dart';
import 'audio_player_widget.dart';
import '../services/download_service.dart';

class ChatMessageWidget extends StatelessWidget {
  final Message message;
  final ChatProvider chatProvider;
  final Conversation conversation;
  final VoidCallback? onScrollToMessage;

  const ChatMessageWidget({
    super.key,
    required this.message,
    required this.chatProvider,
    required this.conversation,
    this.onScrollToMessage,
  });

  @override
  Widget build(BuildContext context) {
    final isCurrentUser = message.sender == chatProvider.currentUser?.id;
    final isGroupChat = conversation.type == 'group';
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
                      color: Theme.of(context).colorScheme.surfaceVariant,
                      borderRadius: BorderRadius.circular(16),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        // Reply context (if this message is a reply)
                        MessageReplyWidget(
                          message: message,
                          conversationId: conversation.id,
                          onTap: () => _scrollToMessage(message.replyTo!),
                        ),

                        MessageContentWidget(
                          message: message,
                          isCurrentUser: isCurrentUser,
                        ),
                        const SizedBox(height: 4),
                        Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              Utils.formatTime(message.createdAt),
                              style: Theme.of(context).textTheme.bodySmall
                                  ?.copyWith(
                                    color: Theme.of(
                                      context,
                                    ).colorScheme.onSurfaceVariant,
                                  ),
                            ),
                            if (message.isEdited) ...[
                              const SizedBox(width: 4),
                              Icon(
                                Icons.edit_rounded,
                                size: 12,
                                color: Theme.of(
                                  context,
                                ).colorScheme.onSurfaceVariant,
                              ),
                            ],
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Reply button and reply count
                  Padding(
                    padding: const EdgeInsets.only(top: 4),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        MessageReplyCountWidget(
                          message: message,
                          conversationId: conversation.id,
                          onTap: () => _showReplies(context, message),
                        ),
                        const SizedBox(width: 8),
                        MessageReplyButton(
                          message: message,
                          conversationId: conversation.id,
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
            color: isCurrentUser
                ? Theme.of(context).colorScheme.primaryContainer
                : Theme.of(context).colorScheme.surfaceVariant,
            borderRadius: BorderRadius.circular(16),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Show sender name for direct chat when not current user
              if (!isCurrentUser && !isGroupChat)
                Text(
                  senderDisplayName,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),

              // Reply context (if this message is a reply)
              MessageReplyWidget(
                message: message,
                conversationId: conversation.id,
                onTap: () => _scrollToMessage(message.replyTo!),
              ),

              // Message content based on type
              MessageContentWidget(
                message: message,
                isCurrentUser: isCurrentUser,
              ),

              const SizedBox(height: 4),
              Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    Utils.formatTime(message.createdAt),
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: isCurrentUser
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),

                  if (message.isEdited) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.edit_rounded,
                      size: 12,
                      color: isCurrentUser
                          ? Theme.of(
                              context,
                            ).colorScheme.onPrimaryContainer.withOpacity(0.7)
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ],

                  if (isCurrentUser) ...[
                    const SizedBox(width: 4),
                    Icon(
                      Icons.check_rounded,
                      size: 12,
                      color: Theme.of(
                        context,
                      ).colorScheme.onPrimaryContainer.withOpacity(0.7),
                    ),
                  ],
                ],
              ),

              // Reply button and reply count
              Padding(
                padding: const EdgeInsets.only(top: 4),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    MessageReplyCountWidget(
                      message: message,
                      conversationId: conversation.id,
                      onTap: () => _showReplies(context, message),
                    ),
                    const SizedBox(width: 8),
                    MessageReplyButton(
                      message: message,
                      conversationId: conversation.id,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  void _scrollToMessage(String messageId) {
    if (onScrollToMessage != null) {
      onScrollToMessage!();
    }
  }

  void _showReplies(BuildContext context, Message message) {
    final replies = chatProvider.getRepliesToMessage(
      conversation.id,
      message.id,
    );

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (context) {
        return DraggableScrollableSheet(
          initialChildSize: 0.6,
          minChildSize: 0.3,
          maxChildSize: 0.9,
          builder: (context, scrollController) {
            return Container(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: [
                  Text(
                    '${replies.length} ${replies.length == 1 ? 'Reply' : 'Replies'}',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      controller: scrollController,
                      itemCount: replies.length,
                      itemBuilder: (context, index) {
                        return ChatMessageWidget(
                          message: replies[index],
                          chatProvider: chatProvider,
                          conversation: conversation,
                        );
                      },
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }
}

class MessageContentWidget extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const MessageContentWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    switch (message.type) {
      case ApiConstants.messageTypeImage:
        return ImageMessageWidget(
          message: message,
          isCurrentUser: isCurrentUser,
        );
      case ApiConstants.messageTypeFile:
      case ApiConstants.messageTypeVideo:
      case ApiConstants.messageTypeAudio:
      case ApiConstants.messageTypeDocument:
        return FileMessageWidget(
          message: message,
          isCurrentUser: isCurrentUser,
        );
      case ApiConstants.messageTypeText:
      default:
        return TextMessageWidget(
          message: message,
          isCurrentUser: isCurrentUser,
        );
    }
  }
}

class TextMessageWidget extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const TextMessageWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      message.content,
      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
        color: isCurrentUser
            ? Theme.of(context).colorScheme.onPrimaryContainer
            : Theme.of(context).colorScheme.onSurfaceVariant,
      ),
    );
  }
}

class ImageMessageWidget extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const ImageMessageWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (message.attachments != null && message.attachments!.isNotEmpty)
          GestureDetector(
            onTap: () {
              final imageUrl = message.attachments!.first.url.startsWith('http')
                  ? message.attachments!.first.url
                  : ApiConstants.baseUrl +
                        ApiConstants.attachments +
                        '/' +
                        message.attachments!.first.url;

              ImageViewerDialog.show(
                context,
                imageUrl,
                heroTag: 'image_${message.id}',
                title: message.attachments!.first.name,
              );
            },
            child: Hero(
              tag: 'image_${message.id}',
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: Image.network(
                  // Check if URL is already full URL or needs base URL
                  message.attachments!.first.url.startsWith('http')
                      ? message.attachments!.first.url
                      : ApiConstants.baseUrl +
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
                            Icons.error_rounded,
                            color: isCurrentUser
                                ? Theme.of(context)
                                      .colorScheme
                                      .onPrimaryContainer
                                      .withOpacity(0.7)
                                : Theme.of(
                                    context,
                                  ).colorScheme.onSurfaceVariant,
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Failed to load image',
                            style: Theme.of(context).textTheme.bodySmall
                                ?.copyWith(
                                  color: isCurrentUser
                                      ? Theme.of(context)
                                            .colorScheme
                                            .onPrimaryContainer
                                            .withOpacity(0.7)
                                      : Theme.of(
                                          context,
                                        ).colorScheme.onSurfaceVariant,
                                ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }
}

class FileMessageWidget extends StatelessWidget {
  final Message message;
  final bool isCurrentUser;

  const FileMessageWidget({
    super.key,
    required this.message,
    required this.isCurrentUser,
  });

  @override
  Widget build(BuildContext context) {
    final attachment = message.attachments?.first;
    if (attachment == null) {
      return const SizedBox.shrink();
    }

    final attachmentUrl = attachment.url.startsWith('http')
        ? attachment.url
        : ApiConstants.baseUrl +
              ApiConstants.attachments +
              '/' +
              attachment.url;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Handle different attachment types
        if (_isVideoAttachment(attachment))
          _buildVideoAttachment(context, attachment, attachmentUrl)
        else if (_isAudioAttachment(attachment))
          _buildAudioAttachment(context, attachment, attachmentUrl)
        else
          _buildFileAttachment(context, attachment, attachmentUrl),

        // Show message content if available
        if (message.content.isNotEmpty)
          Padding(
            padding: const EdgeInsets.only(top: 8),
            child: Text(
              message.content,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.onPrimaryContainer
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildVideoAttachment(
    BuildContext context,
    dynamic attachment,
    String url,
  ) {
    return GestureDetector(
      onTap: () {
        VideoPlayerDialog.show(context, url, title: attachment.name ?? 'Video');
      },
      child: Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.black,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Stack(
          alignment: Alignment.center,
          children: [
            // Video thumbnail placeholder
            Container(
              width: double.infinity,
              height: double.infinity,
              decoration: BoxDecoration(
                color: Colors.black54,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                Icons.video_library_rounded,
                color: Colors.white,
                size: 48,
              ),
            ),
            // Play button overlay
            Container(
              decoration: BoxDecoration(
                color: Colors.black54,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  VideoPlayerDialog.show(
                    context,
                    url,
                    title: attachment.name ?? 'Video',
                  );
                },
                icon: const Icon(
                  Icons.play_arrow_rounded,
                  color: Colors.white,
                  size: 32,
                ),
              ),
            ),
            // Download button
            Positioned(
              top: 8,
              right: 8,
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.black54,
                  shape: BoxShape.circle,
                ),
                child: IconButton(
                  onPressed: () =>
                      _downloadAttachment(context, attachment, url),
                  icon: const Icon(
                    Icons.download_rounded,
                    color: Colors.white,
                    size: 20,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAudioAttachment(
    BuildContext context,
    dynamic attachment,
    String url,
  ) {
    return GestureDetector(
      onTap: () {
        AudioPlayerDialog.show(context, url, title: attachment.name ?? 'Audio');
      },
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Container(
              decoration: BoxDecoration(
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.primary
                    : Theme.of(context).colorScheme.outline,
                shape: BoxShape.circle,
              ),
              child: IconButton(
                onPressed: () {
                  AudioPlayerDialog.show(
                    context,
                    url,
                    title: attachment.name ?? 'Audio',
                  );
                },
                icon: Icon(
                  Icons.play_arrow_rounded,
                  color: isCurrentUser
                      ? Theme.of(context).colorScheme.onPrimary
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name ?? 'Audio file',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCurrentUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (attachment.size != null)
                    Text(
                      _formatFileSize(attachment.size),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCurrentUser
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            IconButton(
              onPressed: () => _downloadAttachment(context, attachment, url),
              icon: Icon(
                Icons.download_rounded,
                color: isCurrentUser
                    ? Theme.of(context).colorScheme.onPrimary
                    : Theme.of(context).colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFileAttachment(
    BuildContext context,
    dynamic attachment,
    String url,
  ) {
    return GestureDetector(
      onTap: () => _downloadAttachment(context, attachment, url),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: isCurrentUser
              ? Theme.of(context).colorScheme.primary.withOpacity(0.8)
              : Theme.of(context).colorScheme.surfaceVariant,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(
              _getFileIconByType(attachment),
              color: isCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
              size: 32,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    attachment.name ?? 'Unknown file',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: isCurrentUser
                          ? Theme.of(context).colorScheme.onPrimary
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontWeight: FontWeight.w500,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  if (attachment.size != null)
                    Text(
                      _formatFileSize(attachment.size),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: isCurrentUser
                            ? Theme.of(
                                context,
                              ).colorScheme.onPrimary.withOpacity(0.8)
                            : Theme.of(context).colorScheme.onSurfaceVariant,
                      ),
                    ),
                ],
              ),
            ),
            Icon(
              Icons.download_rounded,
              color: isCurrentUser
                  ? Theme.of(context).colorScheme.onPrimary
                  : Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ],
        ),
      ),
    );
  }

  bool _isVideoAttachment(dynamic attachment) {
    final type =
        attachment.type?.toLowerCase() ??
        attachment['type']?.toString().toLowerCase();
    return type == 'video';
  }

  bool _isAudioAttachment(dynamic attachment) {
    final type =
        attachment.type?.toLowerCase() ??
        attachment['type']?.toString().toLowerCase();
    return type == 'audio';
  }

  void _downloadAttachment(
    BuildContext context,
    dynamic attachment,
    String url,
  ) {
    final type =
        attachment.type?.toLowerCase() ??
        attachment['type']?.toString().toLowerCase();
    final fileName = attachment.name ?? attachment['name']?.toString();

    switch (type) {
      case 'video':
        DownloadService.downloadVideo(
          context: context,
          videoUrl: url,
          fileName: fileName,
        );
        break;
      case 'audio':
        DownloadService.downloadAudio(
          context: context,
          audioUrl: url,
          fileName: fileName,
        );
        break;
      case 'image':
        DownloadService.downloadImage(
          context: context,
          imageUrl: url,
          fileName: fileName,
        );
        break;
      default:
        DownloadService.downloadGenericFile(
          context: context,
          fileUrl: url,
          fileName: fileName,
        );
    }
  }

  IconData _getFileIcon(String fileName) {
    final extension = fileName.split('.').last.toLowerCase();
    switch (extension) {
      case 'pdf':
        return Icons.picture_as_pdf_rounded;
      case 'doc':
      case 'docx':
        return Icons.description_rounded;
      case 'xls':
      case 'xlsx':
        return Icons.table_chart_rounded;
      case 'ppt':
      case 'pptx':
        return Icons.slideshow_rounded;
      case 'txt':
        return Icons.text_snippet_rounded;
      case 'zip':
      case 'rar':
        return Icons.archive_rounded;
      case 'mp3':
      case 'wav':
        return Icons.audio_file_rounded;
      case 'mp4':
      case 'mov':
        return Icons.video_file_rounded;
      default:
        return Icons.insert_drive_file_rounded;
    }
  }

  // New method to get icon based on attachment type from API
  IconData _getFileIconByType(dynamic attachment) {
    if (attachment == null) return Icons.insert_drive_file_rounded;

    // Check if attachment has type field from API
    final type =
        attachment.type?.toLowerCase() ??
        attachment['type']?.toString().toLowerCase();

    if (type != null) {
      switch (type) {
        case 'video':
          return Icons.video_file_rounded;
        case 'audio':
          return Icons.audio_file_rounded;
        case 'image':
          return Icons.image_rounded;
        case 'document':
          return Icons.description_rounded;
        default:
          break;
      }
    }

    // Fallback to filename extension
    final fileName = attachment.name ?? attachment['name']?.toString() ?? '';
    return _getFileIcon(fileName);
  }

  String _formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024)
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
