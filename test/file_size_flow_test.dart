import 'package:flutter_test/flutter_test.dart';
import 'package:mercury_test/constants/file_constants.dart';

void main() {
  group('File Size Limit Flow Tests', () {
    test('Free user with 15MB file should be blocked', () {
      const isPremium = false;
      const fileSize = 15 * 1024 * 1024; // 15MB

      final isAllowed = FileConstants.isFileSizeAllowed(fileSize, isPremium);
      expect(isAllowed, isFalse);

      final errorMessage = FileConstants.getFileTooLargeMessage(isPremium);
      expect(errorMessage, contains('premium'));
      expect(errorMessage, contains('10MB'));
      expect(errorMessage, contains('100MB'));
    });

    test('Free user with 5MB file should be allowed', () {
      const isPremium = false;
      const fileSize = 5 * 1024 * 1024; // 5MB

      final isAllowed = FileConstants.isFileSizeAllowed(fileSize, isPremium);
      expect(isAllowed, isTrue);
    });

    test('Premium user with 50MB file should be allowed', () {
      const isPremium = true;
      const fileSize = 50 * 1024 * 1024; // 50MB

      final isAllowed = FileConstants.isFileSizeAllowed(fileSize, isPremium);
      expect(isAllowed, isTrue);
    });

    test('Premium user with 150MB file should be blocked', () {
      const isPremium = true;
      const fileSize = 150 * 1024 * 1024; // 150MB

      final isAllowed = FileConstants.isFileSizeAllowed(fileSize, isPremium);
      expect(isAllowed, isFalse);

      final errorMessage = FileConstants.getFileTooLargeMessage(isPremium);
      expect(errorMessage, contains('100MB'));
      expect(
        errorMessage,
        isNot(contains('premium')),
      ); // Should not suggest upgrade
    });

    test('File size formatting works correctly', () {
      expect(FileConstants.formatFileSize(5 * 1024 * 1024), equals('5.0 MB'));
      expect(FileConstants.formatFileSize(15 * 1024 * 1024), equals('15.0 MB'));
      expect(FileConstants.formatFileSize(500 * 1024), equals('500.0 KB'));
    });
  });
}
