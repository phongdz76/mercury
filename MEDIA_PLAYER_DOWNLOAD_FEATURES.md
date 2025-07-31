# Mercury Chat - Media Player & Download Features

## Tổng quan

Tài liệu này mô tả việc tích hợp các tính năng Media Player và Download vào ứng dụng Mercury Chat.

## Các tính năng đã thêm

### 1. 🎥 Video Player

- **Chức năng**: Phát video trực tiếp trong chat
- **Thư viện**: `video_player` + `chewie`
- **Widget**: `VideoPlayerWidget` & `VideoPlayerDialog`

**Tính năng:**

- Phát video từ URL hoặc local file
- Fullscreen support
- Play/pause controls
- Progress bar với seek functionality
- Volume control
- Error handling và retry
- Loading indicator

**Sử dụng:**

```dart
VideoPlayerDialog.show(
  context,
  videoUrl,
  title: 'Video Title',
);
```

### 2. 🎵 Audio Player

- **Chức năng**: Phát audio trực tiếp trong chat
- **Thư viện**: `audioplayers`
- **Widget**: `AudioPlayerWidget` & `AudioPlayerDialog`

**Tính năng:**

- Phát audio từ URL hoặc local file
- Play/pause controls
- Progress slider với seek
- Duration display
- Compact inline player
- Error handling và retry

**Sử dụng:**

```dart
AudioPlayerDialog.show(
  context,
  audioUrl,
  title: 'Audio Title',
  duration: Duration(minutes: 3),
);
```

### 3. 🖼️ Image Viewer

- **Chức năng**: Xem ảnh toàn màn hình với zoom
- **Thư viện**: `photo_view`
- **Widget**: `ImageViewerDialog` & `ImageGalleryViewer`

**Tính năng:**

- Zoom in/out với pinch gesture
- Pan để di chuyển ảnh
- Hero animation transition
- Tap để show/hide controls
- Download button
- Gallery viewer cho nhiều ảnh

**Sử dụng:**

```dart
ImageViewerDialog.show(
  context,
  imageUrl,
  heroTag: 'image_tag',
  title: 'Image Title',
);
```

### 4. 📥 Download Service

- **Chức năng**: Tải xuống file attachments
- **Thư viện**: `dio`, `path_provider`, `permission_handler`
- **Service**: `DownloadService`

**Tính năng:**

- Download file với progress indicator
- Auto request storage permissions
- Unique filename generation
- Support nhiều loại file (image, video, audio, document)
- Download progress dialog
- Error handling và retry
- Save to appropriate directory (Downloads/Documents)

**Sử dụng:**

```dart
DownloadService.downloadVideo(
  context: context,
  videoUrl: url,
  fileName: 'video.mp4',
);
```

## Cấu trúc file mới

```
lib/
├── widgets/
│   ├── video_player_widget.dart      # Video player components
│   ├── audio_player_widget.dart      # Audio player components
│   └── image_viewer_widget.dart      # Image viewer components
├── services/
│   └── download_service.dart         # File download service
└── constants/
    └── app_constants.dart           # Updated with new message types
```

## Dependencies đã thêm

```yaml
dependencies:
  video_player: ^2.8.1 # Video playback
  chewie: ^1.7.4 # Video player UI
  audioplayers: ^5.2.1 # Audio playback
  dio: ^5.4.0 # HTTP client for downloads
  path_provider: ^2.1.2 # File system paths
  permission_handler: ^11.2.0 # Runtime permissions
  photo_view: ^0.14.0 # Image zoom viewer
```

## Android Permissions

Các permissions đã được thêm vào `android/app/src/main/AndroidManifest.xml`:

```xml
<uses-permission android:name="android.permission.INTERNET" />
<uses-permission android:name="android.permission.WRITE_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.READ_EXTERNAL_STORAGE" />
<uses-permission android:name="android.permission.RECORD_AUDIO" />
<uses-permission android:name="android.permission.CAMERA" />
<uses-permission android:name="android.permission.READ_MEDIA_IMAGES" />
<uses-permission android:name="android.permission.READ_MEDIA_VIDEO" />
<uses-permission android:name="android.permission.READ_MEDIA_AUDIO" />
```

## Cách sử dụng

### 1. Gửi file media

- Mở chat screen
- Nhấn nút attachment (📎)
- Chọn loại media:
  - **Gallery**: Chọn ảnh từ thư viện
  - **Camera**: Chụp ảnh
  - **Video**: Chọn video từ thư viện
  - **Record**: Quay video
  - **File**: Chọn file bất kỳ

### 2. Xem media trong chat

- **Ảnh**: Tap để xem toàn màn hình với zoom
- **Video**: Tap để mở video player
- **Audio**: Tap để mở audio player
- **File**: Tap để download

### 3. Download file

- Tap vào attachment hoặc nút download
- Progress dialog sẽ hiển thị
- File được lưu vào thư mục Downloads (Android) hoặc Documents (iOS)

## Message Types mới

```dart
// Đã thêm vào ApiConstants
static const String messageTypeVideo = 'video';
static const String messageTypeAudio = 'audio';
static const String messageTypeDocument = 'document';
```

## Chat Input Widget cập nhật

- UI mới cho attachment picker với icons grid
- Hỗ trợ chọn video từ gallery và record video
- Preview pending attachments trước khi gửi

## Error Handling

- Network errors: Retry mechanism
- Permission denied: User-friendly messages
- File not found: Fallback UI
- Playback errors: Error display với retry button

## Performance Considerations

- Video/Audio: Lazy loading, dispose controllers properly
- Image: Caching với NetworkImage
- Downloads: Progress tracking, cancel functionality
- Memory: Proper widget disposal trong dispose()

## Tương lai

Các tính năng có thể mở rộng:

- Audio recording trong chat
- Video call integration
- File preview cho documents
- Cloud storage integration
- Offline playback support

---

**Lưu ý**: Cần chạy `flutter pub get` để cài đặt dependencies mới và test trên thiết bị thật để đảm bảo permissions hoạt động chính xác.
