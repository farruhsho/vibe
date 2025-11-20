# КРАТКАЯ АННОТАЦИЯ

## Алгоритм рекомендации музыки на основе паттернов с использованием анализа аудио-характеристик

**Автор:** [Ваше имя]
**Год:** 2025
**Объем:** [количество] страниц

---

### АННОТАЦИЯ

Данная дипломная работа посвящена разработке алгоритма рекомендации музыки на основе анализа индивидуальных паттернов прослушивания пользователя. В отличие от существующих подходов, использующих коллаборативную фильтрацию и готовые плейлисты, разработанный алгоритм анализирует четыре ключевые аудио-характеристики треков (энергия, валентность, танцевальность, темп) через Spotify Web API и выявляет персонализированные предпочтения каждого пользователя.

В работе реализован прототип мобильного приложения "Vibe" на платформе Flutter для операционных систем iOS и Android. Приложение интегрировано с Spotify API для получения аудио-характеристик треков и Firebase для хранения данных пользователей. Алгоритм использует статистический подход с гауссовым распределением для оценки соответствия треков паттерну пользователя и применяет эмпирически определенные весовые коэффициенты (энергия 30%, валентность 30%, танцевальность 25%, темп 15%).

Основным результатом работы является функционирующий прототип с аналитической панелью для визуализации паттернов пользователя и системой рейтингов для валидации гипотезы о достижении уровня удовлетворенности выше 4 из 5 баллов. Разработанный алгоритм демонстрирует преимущества персонализированного паттерн-ориентированного подхода над стандартными методами рекомендаций.

**Ключевые слова:** рекомендательные системы, анализ музыки, алгоритм паттернов, аудио-характеристики, персонализация, Flutter, Spotify API, Firebase

---

## ANNOTATION

This bachelor thesis focuses on developing a music recommendation algorithm based on analyzing individual user listening patterns. Unlike existing approaches using collaborative filtering and generic playlists, the developed algorithm analyzes four key audio features of tracks (energy, valence, danceability, tempo) via Spotify Web API and identifies personalized preferences for each user.

The work implements a mobile application prototype "Vibe" on Flutter platform for iOS and Android. The app is integrated with Spotify API for retrieving audio features and Firebase for user data storage. The algorithm uses a statistical approach with Gaussian distribution to evaluate track-pattern matching and applies empirically determined weights (energy 30%, valence 30%, danceability 25%, tempo 15%).

The main result is a working prototype with an analytics dashboard for pattern visualization and a rating system to validate the hypothesis of achieving satisfaction levels above 4 out of 5 points. The developed algorithm demonstrates advantages of personalized pattern-based approach over standard recommendation methods.

**Keywords:** recommendation systems, music analysis, pattern algorithm, audio features, personalization, Flutter, Spotify API, Firebase
