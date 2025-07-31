class FileSizeException implements Exception {
  final String message;
  final bool isPremiumRequired;

  const FileSizeException(this.message, {this.isPremiumRequired = false});

  @override
  String toString() {
    return 'FileSizeException: $message';
  }
}
