import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/foundation.dart';
import '../models/track.dart';

class SpotifyService {
  static const String _cloudFunctionUrl =
      'https://us-central1-aimusic-8a2d1.cloudfunctions.net/vibe_recommend';

  /// Получить AI-рекомендации с обработкой ошибок
  static Future<List<Track>> getAIRecommendations(String mood) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final response = await http
          .post(
        Uri.parse(_cloudFunctionUrl),
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode({
          'user_id': user.uid,
          'mood': mood,
        }),
      )
          .timeout(
        const Duration(seconds: 15),
        onTimeout: () {
          throw TimeoutException('Сервер не отвечает');
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final recommendations = data['recommendations'] as List;

        if (recommendations.isEmpty) {
          throw Exception('Нет рекомендаций для настроения "$mood"');
        }

        return recommendations
            .map((e) => Track.fromJson(e as Map<String, dynamic>))
            .toList();
      } else if (response.statusCode == 400) {
        final error = jsonDecode(response.body);
        throw Exception(error['error'] ?? 'Неверный запрос');
      } else {
        throw Exception('Ошибка сервера: ${response.statusCode}');
      }
    } on SocketException {
      throw Exception('Нет интернета. Проверь подключение.');
    } on TimeoutException {
      throw Exception('Сервер не отвечает. Попробуй позже.');
    } on FormatException {
      throw Exception('Ошибка обработки данных');
    } catch (e) {
      if (e is Exception) rethrow;
      throw Exception('Неизвестная ошибка: $e');
    }
  }

  /// Добавить трек в избранное
  static Future<void> addToFavorites(Track track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      final docData = track.toJson();
      docData['added_at'] = FieldValue.serverTimestamp();

      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(track.id)
          .set(docData);
    } catch (e) {
      throw Exception('Ошибка добавления в избранное: $e');
    }
  }

  /// Удалить трек из избранного
  static Future<void> removeFromFavorites(String trackId) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      throw Exception('Пользователь не авторизован');
    }

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('favorites')
          .doc(trackId)
          .delete();
    } catch (e) {
      throw Exception('Ошибка удаления из избранного: $e');
    }
  }

  /// Добавить трек в историю прослушиваний
  static Future<void> addToHistory(Track track) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .add({
        'track_id': track.id,
        'track_name': track.name,
        'artist': track.artist,
        'timestamp': FieldValue.serverTimestamp(),
      });

      // Удаляем старую историю (храним только последние 50)
      final oldDocs = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('history')
          .orderBy('timestamp', descending: true)
          .get();

      if (oldDocs.docs.length > 50) {
        for (int i = 50; i < oldDocs.docs.length; i++) {
          await oldDocs.docs[i].reference.delete();
        }
      }
    } catch (e) {
      // Не критичная ошибка, просто логируем (ИСПРАВЛЕНО: debugPrint вместо print)
      if (kDebugMode) {
        debugPrint('Warning: Failed to add to history: $e');
      }
    }
  }

  /// Получить актуальный токен (с обновлением если нужно)
  static Future<String?> getValidSpotifyToken() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return null;

    try {
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (!doc.exists) return null;

      final data = doc.data()!;
      final expiresAt = data['token_expires_at'];

      // Проверяем, не протух ли токен
      if (expiresAt != null && expiresAt is Timestamp) {
        final expiry = expiresAt.toDate();
        final now = DateTime.now();

        // Если токен протухает в течение 5 минут - обновляем
        if (now.isAfter(expiry.subtract(const Duration(minutes: 5)))) {
          return await _refreshSpotifyToken(user.uid, data['spotify_refresh_token']);
        }
      }

      return data['spotify_access_token'];
    } catch (e) {
      // ИСПРАВЛЕНО: debugPrint вместо print
      if (kDebugMode) {
        debugPrint('Error getting token: $e');
      }
      return null;
    }
  }

  /// Обновить Spotify токен через refresh token
  static Future<String?> _refreshSpotifyToken(String userId, String refreshToken) async {
    const clientId = '0c4284170a4f4c68a4834dc317e6bd11';
    // NOTE: В продакшене Client Secret должен быть в Cloud Function!

    try {
      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'refresh_token',
          'refresh_token': refreshToken,
          'client_id': clientId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final newAccessToken = data['access_token'];

        // Сохраняем новый токен
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userId)
            .update({
          'spotify_access_token': newAccessToken,
          'token_expires_at': DateTime.now().add(const Duration(hours: 1)),
        });

        return newAccessToken;
      }
    } catch (e) {
      // ИСПРАВЛЕНО: debugPrint вместо print
      if (kDebugMode) {
        debugPrint('Error refreshing token: $e');
      }
    }

    return null;
  }
}