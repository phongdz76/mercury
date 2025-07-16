# Mercury Chat - Flutter Real-time Chat Application

Ứng dụng chat real-time được xây dựng bằng Flutter, sử dụng WebSocket và REST API cho giao tiếp thời gian thực.

## Tính năng chính

### 🔐 Xác thực

- Đăng ký/Đăng nhập với email và password
- JWT token authentication
- Auto-login khi có token hợp lệ

### 💬 Chat Real-time

- Gửi/nhận tin nhắn thời gian thực qua WebSocket
- Hỗ trợ tin nhắn text
- Hiển thị typing indicator
- Read receipts
- Lịch sử tin nhắn

### 👥 Quản lý cuộc trò chuyện

- Tạo cuộc trò chuyện Direct (1-1)
- Tạo cuộc trò chuyện Group (nhiều người)
- Danh sách cuộc trò chuyện
- Thông tin cuộc trò chuyện

### 🌐 Kết nối

- WebSocket connection với auto-reconnect
- Connection status indicator
- Fallback REST API

## Cấu trúc dự án

```
lib/
├── constants/
│   ├── app_constants.dart    # Constants cho API và strings
│   └── app_theme.dart        # Theme và colors
├── models/
│   ├── conversation.dart     # Model cuộc trò chuyện
│   ├── message.dart          # Model tin nhắn
│   ├── user.dart             # Model người dùng
│   └── websocket_event.dart  # Model WebSocket events
├── providers/
│   └── chat_provider.dart    # State management với Provider
├── screens/
│   ├── login_screen.dart     # Màn hình đăng nhập
│   ├── conversations_screen.dart # Danh sách cuộc trò chuyện
│   └── chat_screen.dart      # Màn hình chat
├── services/
│   ├── api_service.dart      # REST API service
│   └── websocket_service.dart # WebSocket service
├── utils/
│   └── utils.dart            # Utility functions
└── main.dart                 # Entry point
```

## Cài đặt và chạy

### 1. Cài đặt Flutter dependencies

```bash
flutter pub get
```

### 2. Cấu hình API endpoint

Trong file `lib/constants/app_constants.dart`, cập nhật:

```dart
static const String baseUrl = 'http://your-api-server:3000';
static const String wsUrl = 'ws://your-api-server:3000/chat/ws';
```

### 3. Chạy ứng dụng

```bash
flutter run
```

## API Requirements

Ứng dụng cần backend API với các endpoints sau:

### Authentication

- `POST /auth/login` - Đăng nhập
- `POST /auth/register` - Đăng ký

### Conversations

- `GET /conversations` - Lấy danh sách cuộc trò chuyện
- `POST /conversations` - Tạo cuộc trò chuyện mới
- `GET /conversations/:id` - Lấy thông tin cuộc trò chuyện

### Messages

- `GET /conversations/:id/messages` - Lấy tin nhắn
- `POST /conversations/:id/messages` - Gửi tin nhắn
- `PUT /messages/:id` - Sửa tin nhắn
- `DELETE /messages/:id` - Xóa tin nhắn

### WebSocket

- `ws://server/chat/ws?token=jwt_token` - WebSocket connection

## Sử dụng

### 1. Đăng nhập/Đăng ký

- Mở ứng dụng
- Nhập email và password
- Chọn Login hoặc Register

### 2. Tạo cuộc trò chuyện

- Trong màn hình Conversations, nhấn nút "+"
- Chọn loại cuộc trò chuyện (Direct/Group)
- Nhập thông tin người tham gia
- Nhấn "Create"

### 3. Chat

- Chọn cuộc trò chuyện từ danh sách
- Nhập tin nhắn trong ô text
- Nhấn "Send" hoặc Enter để gửi

### 4. Tính năng khác

- Connection status hiển thị ở bottom bar
- Typing indicator khi người khác đang gõ
- Timestamp cho mỗi tin nhắn
- Auto-scroll đến tin nhắn mới nhất

## Dependencies

```yaml
dependencies:
  flutter:
    sdk: flutter
  http: ^1.1.0 # REST API calls
  web_socket_channel: ^2.4.0 # WebSocket connection
  provider: ^6.1.1 # State management
  shared_preferences: ^2.2.2 # Local storage
```

## Customization

### Thay đổi theme

Chỉnh sửa `lib/constants/app_theme.dart` để thay đổi màu sắc và theme.

### Thêm tính năng

1. Tạo model mới trong `models/`
2. Cập nhật `ChatProvider` trong `providers/`
3. Thêm UI screen trong `screens/`
4. Cập nhật API service nếu cần

## Troubleshooting

### Connection issues

- Kiểm tra API server đang chạy
- Kiểm tra URL trong `app_constants.dart`
- Kiểm tra network permissions

### Authentication issues

- Kiểm tra JWT token format
- Kiểm tra token expiration
- Clear app data và login lại

### WebSocket issues

- Kiểm tra WebSocket server
- Kiểm tra authentication token
- Kiểm tra network connectivity

## License

MIT License
