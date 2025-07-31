# File Upload Size Limits Implementation

## Overview

Đã triển khai tính năng giới hạn dung lượng upload file dựa trên trạng thái premium của user.

## Features Implemented

### 1. File Size Constants (`lib/constants/file_constants.dart`)

- **Free Users**: Giới hạn upload file tối đa 10MB
- **Premium Users**: Giới hạn upload file tối đa 100MB
- **Avatar Upload**: Giới hạn 5MB cho tất cả user
- Utility functions để format size và check limits

### 2. Exception Handling (`lib/exceptions/file_size_exception.dart`)

- Custom exception class cho file size errors
- Hỗ trợ flag `isPremiumRequired` để phân biệt có cần upgrade premium không

### 3. Upload Service Updates (`lib/services/upload_service.dart`)

- Kiểm tra file size trước khi upload
- Throw `FileSizeException` khi file quá lớn
- Hỗ trợ truyền thông tin user để check premium status

### 4. File Upload Helper (`lib/utils/file_upload_helper.dart`)

- Utility class để xử lý upload với size checking
- Tự động hiển thị dialog khi file quá lớn
- Integration với premium upgrade flow

### 5. UI Components

#### File Size Limit Dialog (`lib/widgets/file_size_exceed_dialog.dart`)

- Dialog thông báo khi file quá lớn
- Hiển thị thông tin premium benefits
- Button upgrade to premium cho free users

#### File Upload Limit Info (`lib/widgets/file_upload_limit_info.dart`)

- Widget hiển thị thông tin giới hạn upload
- Compact version cho attachment modal
- Premium badge cho premium users

### 6. Chat Integration

- Cập nhật `ChatInputWidget` để sử dụng `FileUploadHelper`
- Hiển thị thông tin giới hạn trong attachment modal
- Error handling cho file size exceptions

### 7. Profile Integration

- Cập nhật `ProfileScreen` để handle avatar size limits
- Hiển thị dialog khi avatar quá lớn

## File Size Limits

| User Type | File Upload Limit | Avatar Limit |
| --------- | ----------------- | ------------ |
| Free      | 10MB              | 5MB          |
| Premium   | 100MB             | 5MB          |

## Usage Examples

### Basic File Size Checking

```dart
final isAllowed = FileConstants.isFileSizeAllowed(fileSize, isPremium);
if (!isAllowed) {
  // Handle file too large
}
```

### Upload with Size Checking

```dart
final success = await FileUploadHelper.uploadFileWithLimitCheck(
  context,
  conversationId: conversationId,
  file: file,
  type: type,
);
```

### Display File Size Info

```dart
// Full info widget
FileUploadLimitInfo()

// Compact version
CompactFileUploadLimitInfo()
```

## Error Messages

### Free Users

"File size (XX MB) exceeds the limit for free users (10MB). Upgrade to premium to upload files up to 100MB."

### Premium Users

"File size (XX MB) exceeds the maximum limit (100MB)."

### Avatar

"Avatar size exceeds the maximum limit (5MB)."

## Benefits for Premium Users

- Larger file upload limits (100MB vs 10MB)
- Enhanced file sharing capabilities
- Priority support
- Custom themes
- Unlimited message history

## Technical Implementation

### Flow Diagram

```
User selects file
       ↓
Check file size
       ↓
Size > limit? → Yes → Show upgrade dialog → User can upgrade
       ↓ No
Proceed with upload
       ↓
Upload successful
```

### Integration Points

1. **Chat Screen**: File attachment với size checking
2. **Profile Screen**: Avatar upload với size checking
3. **Upload Service**: Backend integration với size validation
4. **Premium Flow**: Upgrade promotion khi file quá lớn

## Testing

- Unit tests cho FileConstants và exceptions
- Integration tests cho upload flow
- UI tests cho dialogs và widgets

## Benefits

- **User Experience**: Clear feedback về file size limits
- **Monetization**: Incentivize để upgrade premium
- **Performance**: Tránh upload files quá lớn
- **Server Resources**: Kiểm soát bandwidth và storage

## Future Enhancements

- Progress bar cho large file uploads
- File compression options
- Bulk upload với size checking
- Analytics tracking cho upgrade conversions
