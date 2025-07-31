import 'dart:io';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/chat_provider.dart';
import '../exceptions/file_size_exception.dart';
import '../widgets/file_size_exceed_dialog.dart';
import '../constants/file_constants.dart';

class FileUploadHelper {
  /// Upload file with size limit checking and proper error handling
  static Future<bool> uploadFileWithLimitCheck(
    BuildContext context, {
    required String conversationId,
    required File file,
    required String type,
  }) async {
    try {
      final chatProvider = Provider.of<ChatProvider>(context, listen: false);

      // Check file size before attempting upload
      final fileSize = await file.length();
      final isPremium = chatProvider.currentUser?.isPremium ?? false;

      if (!FileConstants.isFileSizeAllowed(fileSize, isPremium)) {
        await _showFileSizeDialog(
          context,
          fileSize: fileSize,
          isPremium: isPremium,
        );
        return false;
      }

      // Proceed with upload
      await chatProvider.addPendingAttachment(
        conversationId: conversationId,
        file: file,
        type: type,
      );

      return true;
    } catch (e) {
      if (e is FileSizeException) {
        await _handleFileSizeException(context, e);
        return false;
      }

      // Handle other exceptions
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Failed to upload file: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return false;
    }
  }

  /// Show file size dialog with appropriate options
  static Future<void> _showFileSizeDialog(
    BuildContext context, {
    required int fileSize,
    required bool isPremium,
  }) async {
    final formattedSize = FileConstants.formatFileSize(fileSize);
    final allowedSize = FileConstants.getFileSizeLabel(isPremium);

    String message;
    bool showUpgradeOption = false;

    if (!isPremium) {
      message =
          'File size ($formattedSize) exceeds the limit for free users ($allowedSize).\n\nUpgrade to premium to upload files up to ${FileConstants.premiumSizeLimit}.';
      showUpgradeOption = true;
    } else {
      message =
          'File size ($formattedSize) exceeds the maximum limit ($allowedSize).';
    }

    await FileSizeExceedDialog.show(
      context,
      message: message,
      showUpgradeOption: showUpgradeOption,
    );
  }

  /// Handle FileSizeException
  static Future<void> _handleFileSizeException(
    BuildContext context,
    FileSizeException exception,
  ) async {
    await FileSizeExceedDialog.show(
      context,
      message: exception.message,
      showUpgradeOption: exception.isPremiumRequired,
    );
  }

  /// Check if file size is allowed for current user
  static Future<bool> isFileSizeAllowed(File file, bool isPremium) async {
    final fileSize = await file.length();
    return FileConstants.isFileSizeAllowed(fileSize, isPremium);
  }

  /// Get file size information for display
  static Future<Map<String, dynamic>> getFileSizeInfo(
    File file,
    bool isPremium,
  ) async {
    final fileSize = await file.length();
    final isAllowed = FileConstants.isFileSizeAllowed(fileSize, isPremium);
    final maxSize = FileConstants.getMaxFileSize(isPremium);

    return {
      'size': fileSize,
      'formattedSize': FileConstants.formatFileSize(fileSize),
      'isAllowed': isAllowed,
      'maxSize': maxSize,
      'maxSizeFormatted': FileConstants.formatFileSize(maxSize),
      'maxSizeLabel': FileConstants.getFileSizeLabel(isPremium),
    };
  }
}
