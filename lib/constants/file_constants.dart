class FileConstants {
  // File size limits (in bytes)
  static const int maxFileSizeForFreeUser =
      10 * 1024 * 1024; // 10MB for free users
  static const int maxFileSizeForPremiumUser =
      100 * 1024 * 1024; // 100MB for premium users

  // Avatar size limit (applies to all users)
  static const int maxAvatarSize = 5 * 1024 * 1024; // 5MB

  // File size labels
  static const String freeSizeLimit = '10MB';
  static const String premiumSizeLimit = '100MB';
  static const String avatarSizeLimit = '5MB';

  // Error messages
  static const String fileTooLargeForFreeUser =
      'File size exceeds the limit for free users (10MB). Upgrade to premium to upload files up to 100MB.';
  static const String fileTooLargeForPremiumUser =
      'File size exceeds the maximum limit (100MB).';
  static const String avatarTooLarge =
      'Avatar size exceeds the maximum limit (5MB).';

  /// Get maximum file size based on user premium status
  static int getMaxFileSize(bool isPremium) {
    return isPremium ? maxFileSizeForPremiumUser : maxFileSizeForFreeUser;
  }

  /// Get file size limit label based on user premium status
  static String getFileSizeLabel(bool isPremium) {
    return isPremium ? premiumSizeLimit : freeSizeLimit;
  }

  /// Get error message for file too large based on user premium status
  static String getFileTooLargeMessage(bool isPremium) {
    return isPremium ? fileTooLargeForPremiumUser : fileTooLargeForFreeUser;
  }

  /// Check if file size is within limit for user
  static bool isFileSizeAllowed(int fileSize, bool isPremium) {
    return fileSize <= getMaxFileSize(isPremium);
  }

  /// Check if avatar size is within limit
  static bool isAvatarSizeAllowed(int fileSize) {
    return fileSize <= maxAvatarSize;
  }

  /// Format file size to human readable format
  static String formatFileSize(int bytes) {
    if (bytes < 1024) return '$bytes B';
    if (bytes < 1024 * 1024) return '${(bytes / 1024).toStringAsFixed(1)} KB';
    if (bytes < 1024 * 1024 * 1024) {
      return '${(bytes / (1024 * 1024)).toStringAsFixed(1)} MB';
    }
    return '${(bytes / (1024 * 1024 * 1024)).toStringAsFixed(1)} GB';
  }
}
