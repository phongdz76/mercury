// Example: How to use the new pending attachments API

// In your chat screen widget:

class ChatScreenExample {
  final ChatProvider chatProvider;
  final String conversationId;

  ChatScreenExample(this.chatProvider, this.conversationId);

  // 1. When user picks a file (image/document)
  Future<void> onFilePicked(File file, String type) async {
    // Upload and add to pending attachments (doesn't send yet)
    await chatProvider.addPendingAttachment(
      conversationId: conversationId,
      file: file,
      type: type, // 'image' or 'file'
    );

    // UI will automatically update via notifyListeners()
    // Show the pending attachment in the input area
  }

  // 2. When user wants to remove a pending attachment
  void onRemoveAttachment(int index) {
    chatProvider.removePendingAttachment(conversationId, index);
  }

  // 3. When user types and sends message
  Future<void> onSendMessage(String text) async {
    if (chatProvider.hasPendingAttachments(conversationId)) {
      // Send message with pending attachments
      await chatProvider.sendMessageWithPendingAttachments(
        conversationId: conversationId,
        content: text, // User's caption/message
      );
    } else {
      // Send normal text message
      await chatProvider.sendMessage(
        conversationId: conversationId,
        content: text,
      );
    }
  }

  // 4. Build pending attachments preview in UI
  Widget buildPendingAttachmentsPreview() {
    final pendingAttachments = chatProvider.getPendingAttachments(
      conversationId,
    );

    if (pendingAttachments.isEmpty) {
      return SizedBox.shrink();
    }

    return Container(
      height: 80,
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        itemCount: pendingAttachments.length,
        itemBuilder: (context, index) {
          final attachment = pendingAttachments[index];

          return Container(
            width: 80,
            height: 80,
            margin: EdgeInsets.only(right: 8),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.grey),
            ),
            child: Stack(
              children: [
                // Preview (image or file icon)
                if (attachment['type'].toString().toLowerCase().contains(
                  'image',
                ))
                  Image.file(
                    attachment['originalFile'] as File,
                    fit: BoxFit.cover,
                    width: 80,
                    height: 80,
                  )
                else
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.insert_drive_file, size: 32),
                        Text(
                          attachment['name'],
                          style: TextStyle(fontSize: 10),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ),
                  ),

                // Remove button
                Positioned(
                  top: 4,
                  right: 4,
                  child: GestureDetector(
                    onTap: () => onRemoveAttachment(index),
                    child: Container(
                      width: 20,
                      height: 20,
                      decoration: BoxDecoration(
                        color: Colors.red,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.close, color: Colors.white, size: 14),
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  // 5. Check if send button should be enabled
  bool get canSendMessage {
    return chatProvider.hasPendingAttachments(conversationId) ||
        messageTextController.text.trim().isNotEmpty;
  }
}

/*
FLOW:
1. User picks file -> addPendingAttachment() -> file uploaded and held
2. User sees preview of pending attachment(s) in input area
3. User can add more attachments or remove them
4. User types caption/message text
5. User hits send -> sendMessageWithPendingAttachments() -> message sent with all attachments
6. Pending attachments cleared automatically

BENEFITS:
- User can review attachments before sending
- Can add multiple attachments
- Can add caption/text to attachments
- Better UX - no accidental sends
- Can cancel/remove attachments before sending
*/
