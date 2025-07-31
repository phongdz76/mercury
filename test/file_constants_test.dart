import 'package:flutter_test/flutter_test.dart';
import 'package:mercury_test/constants/file_constants.dart';
import 'package:mercury_test/exceptions/file_size_exception.dart';

void main() {
  group('FileConstants Tests', () {
    test('should return correct max file size for premium user', () {
      expect(
        FileConstants.getMaxFileSize(true),
        equals(100 * 1024 * 1024),
      ); // 100MB
    });

    test('should return correct max file size for free user', () {
      expect(
        FileConstants.getMaxFileSize(false),
        equals(10 * 1024 * 1024),
      ); // 10MB
    });

    test('should return correct file size label for premium user', () {
      expect(FileConstants.getFileSizeLabel(true), equals('100MB'));
    });

    test('should return correct file size label for free user', () {
      expect(FileConstants.getFileSizeLabel(false), equals('10MB'));
    });

    test('should allow file size within limit for premium user', () {
      expect(
        FileConstants.isFileSizeAllowed(50 * 1024 * 1024, true),
        isTrue,
      ); // 50MB for premium
    });

    test('should not allow file size exceeding limit for premium user', () {
      expect(
        FileConstants.isFileSizeAllowed(150 * 1024 * 1024, true),
        isFalse,
      ); // 150MB for premium
    });

    test('should allow file size within limit for free user', () {
      expect(
        FileConstants.isFileSizeAllowed(5 * 1024 * 1024, false),
        isTrue,
      ); // 5MB for free
    });

    test('should not allow file size exceeding limit for free user', () {
      expect(
        FileConstants.isFileSizeAllowed(15 * 1024 * 1024, false),
        isFalse,
      ); // 15MB for free
    });

    test('should format file size correctly', () {
      expect(FileConstants.formatFileSize(1024), equals('1.0 KB'));
      expect(FileConstants.formatFileSize(1024 * 1024), equals('1.0 MB'));
      expect(
        FileConstants.formatFileSize(1024 * 1024 * 1024),
        equals('1.0 GB'),
      );
      expect(FileConstants.formatFileSize(500), equals('500 B'));
    });

    test('should return correct error message for premium user', () {
      expect(
        FileConstants.getFileTooLargeMessage(true),
        equals('File size exceeds the maximum limit (100MB).'),
      );
    });

    test('should return correct error message for free user', () {
      expect(
        FileConstants.getFileTooLargeMessage(false),
        equals(
          'File size exceeds the limit for free users (10MB). Upgrade to premium to upload files up to 100MB.',
        ),
      );
    });
  });

  group('FileSizeException Tests', () {
    test('should create exception with message and premium required flag', () {
      final exception = FileSizeException(
        'Test message',
        isPremiumRequired: true,
      );
      expect(exception.message, equals('Test message'));
      expect(exception.isPremiumRequired, isTrue);
    });

    test('should create exception with default premium required flag', () {
      final exception = FileSizeException('Test message');
      expect(exception.message, equals('Test message'));
      expect(exception.isPremiumRequired, isFalse);
    });

    test('should return correct string representation', () {
      final exception = FileSizeException('Test message');
      expect(exception.toString(), equals('FileSizeException: Test message'));
    });
  });
}
