import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../constants/app_constants.dart';
import '../constants/file_constants.dart';
import '../widgets/message_reply_widgets.dart';
import '../utils/file_upload_helper.dart';
import '../widgets/file_upload_limit_info.dart';

class ChatInputWidget extends StatefulWidget {
  final TextEditingController messageController;
  final String conversationId;
  final bool isUploading;
  final VoidCallback onSendMessage;
  final ValueChanged<String> onTyping;
  final Function(bool) setUploading;

  const ChatInputWidget({
    super.key,
    required this.messageController,
    required this.conversationId,
    required this.isUploading,
    required this.onSendMessage,
    required this.onTyping,
    required this.setUploading,
  });

  @override
  State<ChatInputWidget> createState() => _ChatInputWidgetState();
}

class _ChatInputWidgetState extends State<ChatInputWidget> {
  final _picker = ImagePicker();

  Future<void> _pickImage() async {
    try {
      final XFile? pickedFile = await _picker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 80,
        maxWidth: 1024,
        maxHeight: 1024,
      );

      if (pickedFile != null) {
        await _sendFileWithOptionalCaption(
          File(pickedFile.path),
          ApiConstants.messageTypeImage,
          'Send Image',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick image: $e'),
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
        await _sendFileWithOptionalCaption(
          File(pickedFile.path),
          ApiConstants.messageTypeImage,
          'Send Photo',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to take photo: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideo() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.gallery,
        maxDuration: const Duration(minutes: 5), // Limit video duration
      );

      if (pickedFile != null) {
        await _sendFileWithOptionalCaption(
          File(pickedFile.path),
          ApiConstants.messageTypeVideo,
          'Send Video',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick video: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _pickVideoFromCamera() async {
    try {
      final XFile? pickedFile = await _picker.pickVideo(
        source: ImageSource.camera,
        maxDuration: const Duration(minutes: 5),
      );

      if (pickedFile != null) {
        await _sendFileWithOptionalCaption(
          File(pickedFile.path),
          ApiConstants.messageTypeVideo,
          'Record Video',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to record video: $e'),
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
        await _sendFileWithOptionalCaption(
          File(result.files.single.path!),
          ApiConstants.messageTypeFile,
          'Send File',
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to pick file: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _sendFileWithOptionalCaption(
    File file,
    String messageType,
    String dialogTitle,
  ) async {
    // Check file size FIRST before showing caption dialog
    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
    final fileSize = await file.length();
    final isPremium = chatProvider.currentUser?.isPremium ?? false;

    // If file is too large, show size limit dialog immediately
    if (!FileConstants.isFileSizeAllowed(fileSize, isPremium)) {
      await FileUploadHelper.uploadFileWithLimitCheck(
        context,
        conversationId: widget.conversationId,
        file: file,
        type: messageType,
      );
      return; // Exit early if file is too large
    }

    final captionController = TextEditingController();
    String? caption;

    // Show dialog to optionally add caption
    final shouldSend = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text(dialogTitle),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('File: ${file.path.split('/').last}'),
              Text('Size: ${FileConstants.formatFileSize(fileSize)}'),
              const SizedBox(height: 16),
              TextField(
                controller: captionController,
                decoration: const InputDecoration(
                  hintText: 'Add a caption (optional)',
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancel'),
            ),
            ElevatedButton(
              onPressed: () {
                caption = captionController.text.trim();
                Navigator.of(context).pop(true);
              },
              child: const Text('Send'),
            ),
          ],
        );
      },
    );

    if (shouldSend == true) {
      try {
        widget.setUploading(true);

        // Use FileUploadHelper to handle file size checking (again for safety)
        final success = await FileUploadHelper.uploadFileWithLimitCheck(
          context,
          conversationId: widget.conversationId,
          file: file,
          type: messageType,
        );

        if (success) {
          // Send the message with pending attachments and caption
          await chatProvider.sendMessageWithPendingAttachments(
            conversationId: widget.conversationId,
            content: caption ?? '',
          );
        }

        widget.setUploading(false);
      } catch (e) {
        widget.setUploading(false);
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

    captionController.dispose();
  }

  void _showAttachmentOptions() {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (BuildContext context) {
        return Container(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                AppStrings.selectAttachment,
                style: Theme.of(
                  context,
                ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w600),
              ),
              const SizedBox(height: 12),

              // File size limit info
              const CompactFileUploadLimitInfo(),

              const SizedBox(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo_rounded,
                    label: 'Gallery',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt_rounded,
                    label: 'Camera',
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam_rounded,
                    label: 'Video',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.video_camera_back_rounded,
                    label: 'Record',
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideoFromCamera();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.attach_file_rounded,
                    label: 'File',
                    onTap: () {
                      Navigator.pop(context);
                      _pickFile();
                    },
                  ),
                  const SizedBox(width: 60), // Placeholder for alignment
                ],
              ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildAttachmentOption({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: colorScheme.primaryContainer,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: colorScheme.onPrimaryContainer, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              color: colorScheme.onSurfaceVariant,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.surface,
        border: Border(top: BorderSide(color: colorScheme.outlineVariant)),
      ),
      child: Column(
        children: [
          // Pending attachments preview
          PendingAttachmentsWidget(conversationId: widget.conversationId),

          // Reply preview (if replying)
          ReplyPreviewWidget(conversationId: widget.conversationId),

          // Upload progress indicator
          if (widget.isUploading)
            Container(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: colorScheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'Uploading...',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ),
            ),

          // Message input row
          Row(
            children: [
              IconButton(
                onPressed: widget.isUploading ? null : _showAttachmentOptions,
                icon: const Icon(Icons.attach_file_rounded),
                color: colorScheme.primary,
              ),
              Expanded(
                child: TextField(
                  controller: widget.messageController,
                  decoration: InputDecoration(
                    hintText: AppStrings.typeMessage,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(24),
                      borderSide: BorderSide.none,
                    ),
                    filled: true,
                    fillColor: colorScheme.surfaceVariant,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 20,
                      vertical: 12,
                    ),
                  ),
                  onChanged: widget.onTyping,
                  onSubmitted: (_) => widget.onSendMessage(),
                  maxLines: null,
                  enabled: !widget.isUploading,
                ),
              ),
              const SizedBox(width: 12),
              FloatingActionButton.small(
                onPressed: widget.isUploading ? null : widget.onSendMessage,
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                child: const Icon(Icons.send_rounded),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class PendingAttachmentsWidget extends StatelessWidget {
  final String conversationId;

  const PendingAttachmentsWidget({super.key, required this.conversationId});

  IconData _getAttachmentIcon(String type) {
    switch (type.toLowerCase()) {
      case 'image':
        return Icons.image;
      case 'video':
        return Icons.video_file;
      case 'audio':
        return Icons.audio_file;
      case 'document':
      case 'file':
      default:
        return Icons.attach_file;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<ChatProvider>(
      builder: (context, chatProvider, child) {
        final pendingAttachments = chatProvider.getPendingAttachments(
          conversationId,
        );
        if (pendingAttachments.isNotEmpty) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue.shade200),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Icon(
                      Icons.attach_file,
                      size: 16,
                      color: Colors.blue.shade700,
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${pendingAttachments.length} file(s) ready to send',
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.blue.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const Spacer(),
                    InkWell(
                      onTap: () =>
                          chatProvider.clearPendingAttachments(conversationId),
                      child: Icon(
                        Icons.close,
                        size: 16,
                        color: Colors.blue.shade700,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                ...pendingAttachments.asMap().entries.map((entry) {
                  final index = entry.key;
                  final attachment = entry.value;
                  return Padding(
                    padding: const EdgeInsets.only(top: 2),
                    child: Row(
                      children: [
                        Icon(
                          _getAttachmentIcon(
                            attachment['type']?.toString().toLowerCase() ??
                                'file',
                          ),
                          size: 14,
                          color: Colors.blue.shade600,
                        ),
                        const SizedBox(width: 4),
                        Expanded(
                          child: Text(
                            attachment['name'] ?? 'Unknown file',
                            style: const TextStyle(fontSize: 11),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        InkWell(
                          onTap: () => chatProvider.removePendingAttachment(
                            conversationId,
                            index,
                          ),
                          child: Icon(
                            Icons.remove_circle_outline,
                            size: 14,
                            color: Colors.red.shade600,
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }
        return const SizedBox.shrink();
      },
    );
  }
}
