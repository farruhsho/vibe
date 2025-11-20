# Руководство по установке и настройке

## Системные требования

### Минимальные требования
- **ОС**: Windows 10+, macOS 10.14+, Linux (Ubuntu 18.04+)
- **ОЗУ**: 4 GB
- **Дисковое пространство**: 5 GB свободного места
- **Процессор**: Intel Core i3 или эквивалент

### Рекомендуемые требования
- **ОЗУ**: 8 GB+
- **Дисковое пространство**: 10 GB+ SSD
- **Процессор**: Intel Core i5 или выше

## Установка Flutter SDK

### Windows

1. Скачайте Flutter SDK:
```powershell
# Скачайте с официального сайта
https://docs.flutter.dev/get-started/install/windows
```

2. Распакуйте архив в `C:\src\flutter`

3. Добавьте в PATH:
```powershell
$env:Path += ";C:\src\flutter\bin"
```

4. Проверьте установку:
```powershell
flutter doctor
```

### macOS

```bash
# Используя Homebrew
brew install flutter

# Или скачайте вручную
curl -O https://storage.googleapis.com/flutter_infra_release/releases/stable/macos/flutter_macos_3.0.0-stable.zip
unzip flutter_macos_3.0.0-stable.zip
export PATH="$PATH:`pwd`/flutter/bin"
```

### Linux

```bash
# Ubuntu/Debian
sudo snap install flutter --classic

# Или вручную
wget https://storage.googleapis.com/flutter_infra_release/releases/stable/linux/flutter_linux_3.0.0-stable.tar.xz
tar xf flutter_linux_3.0.0-stable.tar.xz
export PATH="$PATH:`pwd`/flutter/bin"
```

## Установка зависимостей проекта

### 1. Клонирование репозитория

```bash
git clone https://github.com/farruhsho/vibe.git
cd vibe
```

### 2. Установка Flutter пакетов

```bash
flutter pub get
```

### 3. Проверка окружения

```bash
flutter doctor -v
```

Убедитесь, что нет критических ошибок (✗). Предупреждения (!) можно игнорировать.

## Настройка Firebase

### 1. Создание проекта Firebase

1. Перейдите на [Firebase Console](https://console.firebase.google.com/)
2. Нажмите "Добавить проект"
3. Введите название: "Vibe Music Recommendations"
4. Отключите Google Analytics (опционально)
5. Нажмите "Создать проект"

### 2. Настройка Authentication

1. В боковом меню выберите "Authentication"
2. Нажмите "Начать"
3. Включите "Email/Password"
4. Сохраните изменения

### 3. Настройка Firestore Database

1. В боковом меню выберите "Firestore Database"
2. Нажмите "Создать базу данных"
3. Выберите "Начать в тестовом режиме"
4. Выберите регион (например, europe-west)
5. Нажмите "Включить"

### 4. Настройка правил безопасности Firestore

```javascript
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    // Пользователи могут читать и писать только свои данные
    match /users/{userId}/{document=**} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    
    // Общедоступные данные (опционально)
    match /public/{document=**} {
      allow read: if true;
      allow write: if request.auth != null;
    }
  }
}
```

### 5. Добавление приложений к проекту

#### Android

1. В Firebase Console нажмите на иконку Android
2. Введите package name: `com.example.vibe`
3. Скачайте `google-services.json`
4. Поместите файл в `android/app/`

#### iOS

1. В Firebase Console нажмите на иконку iOS
2. Введите Bundle ID: `com.example.vibe`
3. Скачайте `GoogleService-Info.plist`
4. Поместите файл в `ios/Runner/`

#### Web

1. В Firebase Console нажмите на иконку Web
2. Зарегистрируйте приложение
3. Скопируйте конфигурацию в `web/index.html`

## Настройка Spotify API

### 1. Создание Spotify Developer аккаунта

1. Перейдите на [Spotify for Developers](https://developer.spotify.com/dashboard)
2. Войдите с помощью Spotify аккаунта
3. Примите Terms of Service

### 2. Создание приложения

1. Нажмите "Create an App"
2. Заполните форму:
   - **App name**: Vibe Music Recommendations
   - **App description**: AI-powered music recommendation system
   - **Redirect URI**: `http://localhost:8080/callback`
3. Примите условия
4. Нажмите "Create"

### 3. Получение credentials

1. Откройте созданное приложение
2. Нажмите "Settings"
3. Скопируйте:
   - **Client ID**
   - **Client Secret** (нажмите "View client secret")

### 4. Добавление credentials в проект

Откройте `lib/services/spotify_service.dart` и замените:

```dart
static const String _clientId = 'ВАШ_CLIENT_ID_ЗДЕСЬ';
static const String _clientSecret = 'ВАШ_CLIENT_SECRET_ЗДЕСЬ';
```

**⚠️ ВАЖНО**: Никогда не коммитьте credentials в Git! Используйте `.env` файлы или environment variables.

## Запуск приложения

### Web

```bash
flutter run -d chrome
```

### Android

1. Подключите Android устройство или запустите эмулятор:
```bash
flutter emulators --launch <emulator_id>
```

2. Запустите приложение:
```bash
flutter run -d android
```

### iOS (только на macOS)

1. Откройте Xcode и настройте signing:
```bash
open ios/Runner.xcworkspace
```

2. Запустите приложение:
```bash
flutter run -d ios
```

## Сборка production версии

### Android APK

```bash
flutter build apk --release
```

Файл находится в: `build/app/outputs/flutter-apk/app-release.apk`

### Android App Bundle (для Google Play)

```bash
flutter build appbundle --release
```

### iOS IPA

```bash
flutter build ios --release
```

### Web

```bash
flutter build web --release
```

Файлы находятся в: `build/web/`

## Troubleshooting

### Проблема: "Flutter doctor" показывает ошибки

**Решение**: Установите недостающие компоненты согласно выводу `flutter doctor`

### Проблема: Firebase не подключается

**Решение**:
1. Проверьте что `google-services.json` / `GoogleService-Info.plist` находятся в правильных директориях
2. Выполните `flutter clean && flutter pub get`
3. Пересоберите приложение

### Проблема: Spotify API возвращает 401 ошибку

**Решение**:
1. Проверьте что Client ID и Client Secret корректны
2. Убедитесь что Redirect URI настроены в Spotify Dashboard
3. Проверьте срок действия токена

### Проблема: Gradle build failed (Android)

**Решение**:
```bash
cd android
./gradlew clean
cd ..
flutter clean
flutter pub get
```

### Проблема: CocoaPods failed (iOS)

**Решение**:
```bash
cd ios
pod deintegrate
pod install
cd ..
flutter clean
flutter pub get
```

## Дополнительные ресурсы

- [Flutter Documentation](https://docs.flutter.dev/)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Spotify Web API Documentation](https://developer.spotify.com/documentation/web-api)
- [GitHub Issues](https://github.com/farruhsho/vibe/issues)

## Поддержка

Если у вас возникли проблемы:
1. Проверьте существующие [Issues](https://github.com/farruhsho/vibe/issues)
2. Создайте новый Issue с подробным описанием проблемы
3. Приложите логи ошибок и скриншоты

---

**Дата обновления**: 2025
**Версия**: 1.0.0
