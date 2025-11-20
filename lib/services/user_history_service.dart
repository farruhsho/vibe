import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';

/// Сервис для управления историей действий пользователя
class UserHistoryService {
  static final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  /// Добавить поисковый запрос в историю
  static Future<void> addSearchQuery(String query) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null || query.trim().isEmpty) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('search_history')
          .add({
        'query': query.trim(),
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Добавлен поисковый запрос: "$query"');

      // Очистка старых записей (оставляем только последние 50)
      _cleanupOldSearches(user.uid);
    } catch (e) {
      debugPrint('❌ Ошибка добавления поискового запроса: $e');
    }
  }

  /// Получить последние поисковые запросы
  static Future<List<String>> getRecentSearches({int limit = 10}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('search_history')
          .orderBy('timestamp', descending: true)
          .limit(limit)
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['query'] as String?)
          .where((q) => q != null && q.isNotEmpty)
          .cast<String>()
          .toSet() // Убираем дубликаты
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения истории поиска: $e');
      return [];
    }
  }

  /// Очистить всю историю поиска
  static Future<void> clearSearchHistory() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('search_history')
          .get();

      for (var doc in snapshot.docs) {
        await doc.reference.delete();
      }

      debugPrint('✅ История поиска очищена');
    } catch (e) {
      debugPrint('❌ Ошибка очистки истории поиска: $e');
    }
  }

  /// Добавить выбранное настроение в историю
  static Future<void> addMoodSelection(String mood) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mood_history')
          .add({
        'mood': mood,
        'timestamp': FieldValue.serverTimestamp(),
      });

      debugPrint('✅ Добавлено настроение: "$mood"');

      // Очистка старых записей
      _cleanupOldMoodSelections(user.uid);
    } catch (e) {
      debugPrint('❌ Ошибка добавления настроения: $e');
    }
  }

  /// Получить последние выбранные настроения
  static Future<List<String>> getRecentMoods({int limit = 5}) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('mood_history')
          .orderBy('timestamp', descending: true)
          .limit(limit * 2) // Берём больше для учёта дубликатов
          .get();

      return snapshot.docs
          .map((doc) => doc.data()['mood'] as String?)
          .where((m) => m != null && m.isNotEmpty)
          .cast<String>()
          .toSet() // Убираем дубликаты
          .take(limit)
          .toList();
    } catch (e) {
      debugPrint('❌ Ошибка получения истории настроений: $e');
      return [];
    }
  }

  /// Получить статистику использования
  static Future<Map<String, dynamic>> getUserStats() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return {};

    try {
      // Количество прослушанных треков
      final listeningHistorySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('listening_history')
          .count()
          .get();

      // Количество поисковых запросов
      final searchHistorySnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('search_history')
          .count()
          .get();

      // Количество избранных треков
      final favoritesSnapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .count()
          .get();

      return {
        'total_tracks_listened': listeningHistorySnapshot.count,
        'total_searches': searchHistorySnapshot.count,
        'total_favorites': favoritesSnapshot.count,
      };
    } catch (e) {
      debugPrint('❌ Ошибка получения статистики: $e');
      return {};
    }
  }

  /// Очистка старых поисковых запросов (оставляем только последние 50)
  static Future<void> _cleanupOldSearches(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('search_history')
          .orderBy('timestamp', descending: true)
          .limit(100) // Берём больше
          .get();

      if (snapshot.docs.length > 50) {
        // Удаляем записи после 50-й
        for (int i = 50; i < snapshot.docs.length; i++) {
          await snapshot.docs[i].reference.delete();
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка очистки старых поисков: $e');
    }
  }

  /// Очистка старых выборов настроений (оставляем только последние 30)
  static Future<void> _cleanupOldMoodSelections(String userId) async {
    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(userId)
          .collection('mood_history')
          .orderBy('timestamp', descending: true)
          .limit(60)
          .get();

      if (snapshot.docs.length > 30) {
        for (int i = 30; i < snapshot.docs.length; i++) {
          await snapshot.docs[i].reference.delete();
        }
      }
    } catch (e) {
      debugPrint('❌ Ошибка очистки старых настроений: $e');
    }
  }
}
