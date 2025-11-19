import functions_framework
from firebase_admin import initialize_app, firestore
import spotipy
from spotipy.oauth2 import SpotifyClientCredentials
import numpy as np
from sklearn.metrics.pairwise import cosine_similarity
import os
from datetime import datetime, timedelta

# Инициализация
initialize_app()
db = firestore.client()

# Spotify клиент
sp = spotipy.Spotify(client_credentials_manager=SpotifyClientCredentials(
    client_id=os.environ.get('SPOTIFY_CLIENT_ID'),
    client_secret=os.environ.get('SPOTIFY_CLIENT_SECRET')
))

# Кэш для рекомендаций
recommendation_cache = {}

def clean_old_cache():
    """Удалить старые записи из кэша (старше 10 минут)"""
    global recommendation_cache
    now = datetime.now()
    to_delete = []

    for key, value in recommendation_cache.items():
        if now - value['timestamp'] > timedelta(minutes=10):
            to_delete.append(key)

    for key in to_delete:
        del recommendation_cache[key]

@functions_framework.http
def vibe_recommend(request):
    """
    AI-рекомендации треков на основе истории прослушиваний и настроения
    """
    try:
        # CORS headers
        if request.method == 'OPTIONS':
            headers = {
                'Access-Control-Allow-Origin': '*',
                'Access-Control-Allow-Methods': 'POST',
                'Access-Control-Allow-Headers': 'Content-Type',
            }
            return ('', 204, headers)

        headers = {'Access-Control-Allow-Origin': '*'}

        # Получаем данные
        data = request.get_json(silent=True) or {}
        user_id = data.get('user_id')
        mood = data.get('mood', 'chill').lower()

        if not user_id:
            return ({'error': 'user_id required'}, 400, headers)

        # Проверяем кэш
        clean_old_cache()
        cache_key = f"{user_id}_{mood}"
        if cache_key in recommendation_cache:
            print(f"✅ Cache hit for {cache_key}")
            return (recommendation_cache[cache_key]['data'], 200, headers)

        # Получаем историю прослушиваний
        history_ref = db.collection('users').document(user_id).collection('history')
        docs = history_ref.order_by('timestamp', direction=firestore.Query.DESCENDING).limit(20).stream()
        history = [doc.to_dict() for doc in docs]
        track_ids = [h.get('track_id') for h in history if h.get('track_id')]

        print(f"📊 Found {len(track_ids)} tracks in history for user {user_id}")

        # Если нет истории — ищем по настроению
        if not track_ids:
            print(f"🔍 No history, searching by mood: {mood}")
            try:
                search = sp.search(q=mood, type='track', limit=5)
                track_ids = [t['id'] for t in search['tracks']['items']]
            except Exception as e:
                print(f"❌ Search error: {e}")
                return ({'error': 'Failed to search tracks'}, 500, headers)

        if not track_ids:
            return ({'recommendations': []}, 200, headers)

        # Получаем аудио-фичи
        try:
            features = [f for f in sp.audio_features(track_ids) if f]
        except Exception as e:
            print(f"❌ Audio features error: {e}")
            return ({'error': 'Failed to get audio features'}, 500, headers)

        if not features:
            return ({'recommendations': []}, 200, headers)

        # Вычисляем средний вектор пользователя
        user_vec = np.mean([
            [f['energy'], f['valence'], f['danceability']]
            for f in features
        ], axis=0)

        print(f"🎯 User vector: {user_vec}")

        # Целевой вектор для настроения
        mood_map = {
            'happy': [0.8, 0.9, 0.8],
            'sad': [0.2, 0.3, 0.3],
            'energetic': [0.9, 0.6, 0.9],
            'chill': [0.4, 0.5, 0.4],
            'focus': [0.6, 0.4, 0.5],
            'party': [0.9, 0.7, 0.95]
        }
        target = np.array(mood_map.get(mood, [0.5, 0.5, 0.5]))

        # Получаем рекомендации от Spotify
        try:
            recs = sp.recommendations(seed_tracks=track_ids[:5], limit=20)
        except Exception as e:
            print(f"❌ Recommendations error: {e}")
            return ({'error': 'Failed to get recommendations'}, 500, headers)

        scored = []

        # Получаем фичи для всех рекомендаций сразу
        rec_ids = [t['id'] for t in recs['tracks']]
        try:
            rec_features = sp.audio_features(rec_ids)
        except Exception as e:
            print(f"❌ Rec features error: {e}")
            rec_features = [None] * len(rec_ids)

        # Скорим каждый трек
        for i, t in enumerate(recs['tracks']):
            f = rec_features[i]
            if not f:
                continue

            vec = np.array([f['energy'], f['valence'], f['danceability']])

            # Взвешенная оценка: 60% совпадение с пользователем + 40% с настроением
            score = (
                    cosine_similarity([user_vec], [vec])[0][0] * 0.6 +
                    cosine_similarity([target], [vec])[0][0] * 0.4
            )

            scored.append({
                'id': t['id'],
                'name': t['name'],
                'artist': t['artists'][0]['name'],
                'image': t['album']['images'][0]['url'] if t['album']['images'] else '',
                'uri': t['uri'],
                'preview_url': t.get('preview_url'),
                'score': round(float(score), 3)
            })

        # Сортируем по скору
        top = sorted(scored, key=lambda x: x['score'], reverse=True)[:10]

        print(f"✅ Returning {len(top)} recommendations")

        result = {'recommendations': top}

        # Сохраняем в кэш
        recommendation_cache[cache_key] = {
            'data': result,
            'timestamp': datetime.now()
        }

        return (result, 200, headers)

    except Exception as e:
        print(f"❌ Unexpected error: {e}")
        import traceback
        traceback.print_exc()
        return ({'error': str(e)}, 500, {'Access-Control-Allow-Origin': '*'})
