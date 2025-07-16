class Config {
  // Development environment
  static const bool isDevelopment = true;

  // API Configuration
  static const String devBaseUrl = 'http://localhost:3000';
  static const String devWsUrl = 'ws://localhost:3000/chat/ws';

  static const String prodBaseUrl = 'https://your-production-api.com';
  static const String prodWsUrl = 'wss://your-production-api.com/chat/ws';

  // Current environment URLs
  static String get baseUrl => isDevelopment ? devBaseUrl : prodBaseUrl;
  static String get wsUrl => isDevelopment ? devWsUrl : prodWsUrl;

  // App Configuration
  static const String appName = 'Mercury Chat';
  static const String appVersion = '1.0.0';

  // WebSocket Configuration
  static const Duration pingInterval = Duration(seconds: 30);
  static const Duration reconnectDelay = Duration(seconds: 5);
  static const int maxReconnectAttempts = 5;

  // Message Configuration
  static const int messagesPerPage = 50;
  static const int maxMessageLength = 1000;

  // UI Configuration
  static const Duration typingIndicatorDelay = Duration(milliseconds: 500);
  static const Duration messageAnimationDuration = Duration(milliseconds: 300);

  // Storage Keys
  static const String tokenKey = 'jwt_token';
  static const String userKey = 'current_user';
  static const String themeKey = 'app_theme';

  // Debug Configuration
  static const bool enableDebugLogs = true;
  static const bool enableMockData = false;
}
