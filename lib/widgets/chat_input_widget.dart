import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../constants/app_constants.dart';
import '../widgets/message_reply_widgets.dart';

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

        final chatProvider = context.read<ChatProvider>();

        // First, add the file as pending attachment
        await chatProvider.addPendingAttachment(
          conversationId: widget.conversationId,
          file: file,
          type: messageType,
        );

        // Then send the message with pending attachments and caption
        await chatProvider.sendMessageWithPendingAttachments(
          conversationId: widget.conversationId,
          content: caption ?? '',
        );

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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.photo,
                    label: 'Gallery',
                    color: Colors.blue,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImage();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.camera_alt,
                    label: 'Camera',
                    color: Colors.green,
                    onTap: () {
                      Navigator.pop(context);
                      _pickImageFromCamera();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.videocam,
                    label: 'Video',
                    color: Colors.purple,
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideo();
                    },
                  ),
                ],
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  _buildAttachmentOption(
                    icon: Icons.video_camera_back,
                    label: 'Record',
                    color: Colors.red,
                    onTap: () {
                      Navigator.pop(context);
                      _pickVideoFromCamera();
                    },
                  ),
                  _buildAttachmentOption(
                    icon: Icons.attach_file,
                    label: 'File',
                    color: Colors.orange,
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
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
              border: Border.all(color: color.withOpacity(0.3)),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.grey[100],
        border: Border(top: BorderSide(color: Colors.grey[300]!)),
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
                onPressed: widget.isUploading ? null : _showAttachmentOptions,
                icon: const Icon(Icons.attach_file),
                color: Colors.blue,
              ),
              Expanded(
                child: TextField(
                  controller: widget.messageController,
                  decoration: const InputDecoration(
                    hintText: AppStrings.typeMessage,
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(
                      horizontal: 12,
                      vertical: 8,
                    ),
                  ),
                  onChanged: widget.onTyping,
                  onSubmitted: (_) => widget.onSendMessage(),
                  maxLines: null,
                  enabled: !widget.isUploading,
                ),
              ),
              const SizedBox(width: 8),
              IconButton(
                onPressed: widget.isUploading ? null : widget.onSendMessage,
                icon: const Icon(Icons.send),
                color: Colors.blue,
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
