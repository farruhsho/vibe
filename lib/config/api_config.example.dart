/// API Configuration Template
///
/// ИНСТРУКЦИЯ:
/// 1. Скопируйте этот файл и переименуйте в api_config.dart
/// 2. Замените значения на ваши реальные API ключи
/// 3. НЕ КОММИТЬТЕ файл api_config.dart в Git!
/// 4. Добавьте api_config.dart в .gitignore
///
/// Для production рекомендуется использовать:
/// - Flutter Environment Variables (--dart-define)
/// - Flutter Secure Storage
/// - Backend API для получения токенов

class ApiConfig {
  // Spotify API credentials
  // Получите ваши ключи на: https://developer.spotify.com/dashboard
  static const String spotifyClientId = 'YOUR_SPOTIFY_CLIENT_ID_HERE';
  static const String spotifyClientSecret = 'YOUR_SPOTIFY_CLIENT_SECRET_HERE';

  // Spotify API endpoints
  static const String spotifyAuthUrl = 'https://accounts.spotify.com/api/token';
  static const String spotifyApiBaseUrl = 'https://api.spotify.com/v1';

  // App configuration
  static const int listeningHistoryLimit = 100;
  static const int maxFavorites = 500;
  static const int recommendationsLimit = 20;
}
