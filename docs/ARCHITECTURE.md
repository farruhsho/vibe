# Архитектура системы Vibe

## Обзор

Vibe использует многоуровневую архитектуру, разделяя приложение на четкие слои ответственности:

1. **Presentation Layer** - UI компоненты (Screens, Widgets)
2. **Business Logic Layer** - Сервисы и алгоритмы
3. **Data Layer** - Модели и источники данных
4. **External Services** - Firebase, Spotify API

## Диаграмма архитектуры

```
┌──────────────────────────────────────────────────────────────┐
│                     PRESENTATION LAYER                        │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌─────────────┐  ┌─────────────┐  ┌──────────────────┐    │
│  │ HomeScreen  │  │SearchScreen │  │ LibraryScreen    │    │
│  │             │  │             │  │                  │    │
│  │ - Moods     │  │ - Real-time │  │ - Genres         │    │
│  │ - AI Recs   │  │   search    │  │ - Favorites      │    │
│  │ - Popular   │  │ - History   │  │ - History        │    │
│  └─────────────┘  └─────────────┘  └──────────────────┘    │
│                                                               │
│  ┌─────────────┐  ┌─────────────┐                           │
│  │ Analytics   │  │  Widgets     │                           │
│  │ Screen      │  │              │                           │
│  │             │  │ - MiniPlayer │                           │
│  │ - Pattern   │  │ - Rating     │                           │
│  │ - Accuracy  │  │   Dialog     │                           │
│  └─────────────┘  └─────────────┘                           │
│                                                               │
└──────────────────────────────────────────────────────────────┘
                            ↕
┌──────────────────────────────────────────────────────────────┐
│                  BUSINESS LOGIC LAYER                         │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────────────────────────────────┐                │
│  │  RecommendationAlgorithm                 │                │
│  │                                          │                │
│  │  calculateScore()                        │                │
│  │  - Feature matching (Gaussian)           │                │
│  │  - Context boost                         │                │
│  │  - Diversity control                     │                │
│  │                                          │                │
│  │  rankTracks()                            │                │
│  │  - Sort by score                         │                │
│  │  - Apply filters                         │                │
│  │                                          │                │
│  │  getDiverseRecommendations()             │                │
│  │  - Tier-based selection                  │                │
│  │  - Sliding window diversity              │                │
│  └──────────────────────────────────────────┘                │
│                                                               │
│  ┌──────────────────────────────────────────┐                │
│  │  PatternAnalyzer                         │                │
│  │                                          │                │
│  │  analyzeUserPattern()                    │                │
│  │  - Statistical analysis                  │                │
│  │  - Mean, StdDev calculation              │                │
│  │  - Time-of-day patterns                  │                │
│  │                                          │                │
│  │  addToListeningHistory()                 │                │
│  │  saveRecommendationRating()              │                │
│  │  getAccuracyStats()                      │                │
│  └──────────────────────────────────────────┘                │
│                                                               │
│  ┌──────────────────────────────────────────┐                │
│  │  SpotifyService                          │                │
│  │                                          │                │
│  │  getAIRecommendations()                  │                │
│  │  - Fetch tracks for mood                 │                │
│  │  - Get audio features                    │                │
│  │  - Apply AI ranking                      │                │
│  │                                          │                │
│  │  searchTracks()                          │                │
│  │  getMultipleAudioFeatures()              │                │
│  └──────────────────────────────────────────┘                │
│                                                               │
└──────────────────────────────────────────────────────────────┘
                            ↕
┌──────────────────────────────────────────────────────────────┐
│                       DATA LAYER                              │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌───────────────┐  ┌─────────────────┐  │
│  │ AudioFeatures│  │ MoodCategory  │  │ Track           │  │
│  │              │  │               │  │                 │  │
│  │ - energy     │  │ - name        │  │ - id            │  │
│  │ - valence    │  │ - icon        │  │ - name          │  │
│  │ - dance      │  │ - color       │  │ - artist        │  │
│  │ - tempo      │  │ - parameters  │  │ - image         │  │
│  │ - acoust.    │  │               │  │ - audioFeatures │  │
│  └──────────────┘  └───────────────┘  └─────────────────┘  │
│                                                               │
│  ┌──────────────┐                                            │
│  │ UserPattern  │                                            │
│  │              │                                            │
│  │ - avgEnergy  │                                            │
│  │ - avgValence │                                            │
│  │ - stdDevs    │                                            │
│  │ - timePrefs  │                                            │
│  └──────────────┘                                            │
│                                                               │
└──────────────────────────────────────────────────────────────┘
                            ↕
┌──────────────────────────────────────────────────────────────┐
│                   EXTERNAL SERVICES                           │
├──────────────────────────────────────────────────────────────┤
│                                                               │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐      │
│  │  Firebase    │  │  Spotify     │  │  Local       │      │
│  │  Firestore   │  │  Web API     │  │  Storage     │      │
│  │              │  │              │  │              │      │
│  │ - users/     │  │ - /search    │  │ - just_audio │      │
│  │   {uid}/     │  │ - /recommend │  │              │      │
│  │   patterns/  │  │ - /audio-    │  │              │      │
│  │   history/   │  │   features   │  │              │      │
│  │   favorites/ │  │ - /tracks    │  │              │      │
│  └──────────────┘  └──────────────┘  └──────────────┘      │
│                                                               │
└──────────────────────────────────────────────────────────────┘
```

## Ключевые компоненты

### 1. Recommendation Algorithm

**Файл**: `lib/services/recommendation_algorithm.dart`

**Функциональность**:
- Расчет score для каждого трека на основе user pattern
- Использование Gaussian distribution для feature matching
- Применение context boost (время суток)
- Контроль разнообразия рекомендаций

**Алгоритм**:
```dart
score = Σ(feature_score_i * weight_i) * (1 + context_boost)

где feature_score_i = exp(-z²/2)
    z = |track_value - user_avg| / user_std_dev
```

**Веса**:
- Energy: 0.25-0.30 (адаптивно)
- Valence: 0.25-0.30 (адаптивно)
- Danceability: 0.20
- Tempo: 0.12
- Acousticness: 0.08
- Mood compatibility: 0.10

### 2. Pattern Analyzer

**Файл**: `lib/services/pattern_analyzer.dart`

**Функциональность**:
- Анализ истории прослушиваний (last 100 tracks)
- Расчет статистических метрик (mean, std dev)
- Анализ time-of-day patterns
- Определение pattern strength

**Метрики**:
```dart
Pattern Strength = 1 - avg(std_dev)
Reliability = tracks_analyzed >= 10
```

### 3. Spotify Service

**Файл**: `lib/services/spotify_service.dart`

**Функциональность**:
- OAuth 2.0 Client Credentials Flow
- Получение рекомендаций по жанрам и audio features
- Поиск треков
- Batch fetching audio features (до 100 треков)

**API Endpoints**:
- `POST /api/token` - получение access token
- `GET /v1/recommendations` - получение рекомендаций
- `GET /v1/search` - поиск треков
- `GET /v1/audio-features` - audio features

### 4. User History Service

**Файл**: `lib/services/user_history_service.dart`

**Функциональность**:
- Сохранение поисковых запросов
- Сохранение выборов настроений
- Получение статистики использования
- Автоматическая очистка старых данных

## Структура данных Firestore

```
users/
  {userId}/
    patterns/
      current/
        - avgEnergy: number
        - avgValence: number
        - avgDanceability: number
        - avgTempo: number
        - energyStdDev: number
        - valenceStdDev: number
        - danceabilityStdDev: number
        - tempoStdDev: number
        - timeOfDayPreferences: map
        - totalTracksAnalyzed: number
        - lastUpdated: timestamp
    
    listening_history/ (subcollection)
      {docId}/
        - track_id: string
        - track_name: string
        - artist: string
        - audio_features: map
        - timestamp: timestamp
    
    favorites/ (subcollection)
      {trackId}/
        - id: string
        - name: string
        - artist: string
        - image: string
        - uri: string
        - added_at: timestamp
    
    ratings/ (subcollection)
      {docId}/
        - track_id: string
        - rating: number (1-5)
        - predicted_score: number (0-1)
        - timestamp: timestamp
    
    search_history/ (subcollection)
      {docId}/
        - query: string
        - timestamp: timestamp
    
    mood_history/ (subcollection)
      {docId}/
        - mood: string
        - timestamp: timestamp
```

## Поток данных

### 1. Получение AI рекомендаций

```
User selects mood
  ↓
HomeScreen.loadAI()
  ↓
SpotifyService.getAIRecommendations()
  ├─→ PatternAnalyzer.getUserPattern()
  ├─→ SpotifyService._getSpotifyTracksForMood()
  │     ├─→ Map mood to genres & audio features
  │     └─→ Spotify API: GET /recommendations
  ├─→ SpotifyService.getMultipleAudioFeatures()
  │     └─→ Spotify API: GET /audio-features?ids=...
  ├─→ RecommendationAlgorithm.rankTracks()
  │     ├─→ calculateScore() for each track
  │     └─→ Sort by score
  └─→ RecommendationAlgorithm.getDiverseRecommendations()
        └─→ Apply tier-based diversity
  ↓
Display tracks with scores
```

### 2. Обновление pattern

```
User plays track
  ↓
PatternAnalyzer.addToListeningHistory()
  ├─→ Save to Firestore: listening_history/
  └─→ Limit to 100 tracks
  ↓
PatternAnalyzer.analyzeUserPattern()
  ├─→ Fetch last 100 tracks
  ├─→ Calculate averages (energy, valence, etc.)
  ├─→ Calculate std devs
  ├─→ Analyze time-of-day patterns
  └─→ Save to Firestore: patterns/current
```

### 3. Получение рейтингов

```
User rates recommendation
  ↓
RatingDialog.submit()
  ↓
PatternAnalyzer.saveRecommendationRating()
  └─→ Save: rating, predicted_score, timestamp
  ↓
PatternAnalyzer.getAccuracyStats()
  ├─→ Calculate avg_rating
  ├─→ Calculate accuracy = 1 - avg_error
  └─→ Return stats
  ↓
Display in AnalyticsScreen
```

## Оптимизация производительности

### 1. Кэширование

- **Spotify Access Token**: кэшируется на 1 час
- **User Pattern**: кэшируется в памяти, обновляется при воспроизведении

### 2. Batch Operations

- Audio features fetching: до 100 треков за раз
- Firestore queries: лимитированы до 100 документов

### 3. Lazy Loading

- Списки треков загружаются по мере прокрутки
- Изображения загружаются асинхронно с placeholder

### 4. Offline Support

- История прослушиваний кэшируется локально
- Рекомендации доступны офлайн (last fetched)

## Безопасность

### 1. Authentication

- Firebase Authentication с Email/Password
- Автоматический refresh токена

### 2. Authorization

- Firestore Security Rules:
```javascript
match /users/{userId}/{document=**} {
  allow read, write: if request.auth.uid == userId;
}
```

### 3. API Keys

- Spotify credentials хранятся в защищенных переменных
- ⚠️ В production используйте environment variables

### 4. Data Validation

- Client-side validation перед отправкой в Firestore
- Server-side validation через Firebase Rules

## Масштабируемость

### Горизонтальное масштабирование

- Firebase автоматически масштабирует Firestore
- Cloud Functions (опционально) для тяжелых вычислений

### Вертикальное масштабирование

- Оптимизация запросов (indexes)
- Denormalization данных
- Pagination списков

### Лимиты

- Spotify API: 
  - Rate limit: 180 requests/minute
  - Burst: до 100 requests
- Firebase:
  - Reads: 50K/day (free tier)
  - Writes: 20K/day (free tier)

## Тестирование

См. файл `TESTING.md` для подробной информации о:
- Unit tests
- Widget tests
- Integration tests
- Performance tests

---

**Версия**: 1.0.0
**Дата обновления**: 2025
