# Demo Flow: Free User Upload File > 10MB

## Scenario: User free cố upload file 15MB

### 1. User Picks File

```dart
// User chọn file từ gallery/camera/file picker
final XFile? pickedFile = await _picker.pickImage(source: ImageSource.gallery);
```

### 2. File Size Check (Immediate)

```dart
// Ngay khi pick xong, check file size TRƯỚC KHI hiển thị caption dialog
final fileSize = await file.length(); // 15MB = 15,728,640 bytes
final isPremium = currentUser?.isPremium ?? false; // false for free user

if (!FileConstants.isFileSizeAllowed(fileSize, isPremium)) {
  // 15MB > 10MB => Show premium dialog immediately
  await FileUploadHelper.uploadFileWithLimitCheck(...);
  return; // Exit early, không hiển thị caption dialog
}
```

### 3. Premium Dialog Display

```dart
FileSizeExceedDialog.show(
  context,
  message: "File size (15.0 MB) exceeds the limit for free users (10MB).
           Upgrade to premium to upload files up to 100MB.",
  showUpgradeOption: true, // Show upgrade button
);
```

### 4. Dialog UI

```
┌─────────────────────────────────────┐
│ ⚠️  File Size Limit                 │
├─────────────────────────────────────┤
│ File size (15.0 MB) exceeds the     │
│ limit for free users (10MB).        │
│                                     │
│ Upgrade to premium to upload files  │
│ up to 100MB.                        │
│                                     │
│ ⭐ Premium Benefits:                │
│ ✅ Upload files up to 100MB         │
│ ✅ Unlimited message history        │
│ ✅ HD video calls                   │
│ ✅ Priority support                 │
├─────────────────────────────────────┤
│           [Cancel] [Upgrade]        │
└─────────────────────────────────────┘
```

### 5. User Actions

- **Cancel**: Đóng dialog, quay về chat
- **Upgrade to Premium**: Navigate to `PremiumPurchaseScreen`

## Flow Chart

```
User picks file (15MB)
        ↓
Check file size immediately
        ↓
15MB > 10MB (free limit)?
        ↓ YES
Show premium upgrade dialog
        ↓
User sees upgrade option
        ↓
[Cancel] ← User → [Upgrade to Premium]
        ↓                    ↓
    Back to chat      Navigate to purchase
```

## Code Implementation

```dart
Future<void> _sendFileWithOptionalCaption(File file, String messageType, String dialogTitle) async {
  // 🔥 KEY: Check file size FIRST, before caption dialog
  final fileSize = await file.length();
  final isPremium = chatProvider.currentUser?.isPremium ?? false;

  if (!FileConstants.isFileSizeAllowed(fileSize, isPremium)) {
    // 🚨 Show premium dialog immediately for free users with large files
    await FileUploadHelper.uploadFileWithLimitCheck(context, ...);
    return; // Stop here, don't show caption dialog
  }

  // Only show caption dialog if file size is OK
  final shouldSend = await showDialog<bool>(...);
  // ... rest of upload logic
}
```

## Benefits

✅ **Immediate feedback**: User biết ngay file quá lớn
✅ **Clear upgrade path**: Button upgrade premium rõ ràng
✅ **No wasted time**: Không cần nhập caption rồi mới báo lỗi
✅ **Better UX**: Premium benefits hiển thị trong dialog
✅ **Monetization**: Encourage upgrade ngay khi cần thiết
