/// Dependency Injection Configuration
///
/// Sets up the service locator (GetIt) with all dependencies.
/// This provides a clean way to inject dependencies throughout the app.

import 'package:get_it/get_it.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

import '../utils/deep_link_handler.dart';
import '../../data/datasources/remote/spotify_auth_datasource.dart';
import '../../data/datasources/remote/spotify_api_datasource.dart';
import '../../data/datasources/local/player_service.dart';
import '../../presentation/blocs/auth/auth_bloc.dart';
import '../../presentation/blocs/player/player_bloc.dart';

/// Global service locator instance
final sl = GetIt.instance;

/// Initialize all dependencies
Future<void> initDependencies() async {
  // ============== EXTERNAL SERVICES ==============
  sl.registerLazySingleton<FirebaseAuth>(() => FirebaseAuth.instance);
  sl.registerLazySingleton<FirebaseFirestore>(() => FirebaseFirestore.instance);

  // ============== CORE UTILITIES ==============
  sl.registerLazySingleton<DeepLinkHandler>(() => DeepLinkService.instance);

  // ============== DATA SOURCES ==============

  // Spotify Auth
  sl.registerLazySingleton<SpotifyAuthDatasource>(
    () => SpotifyAuthDatasource(),
  );

  // Spotify API (depends on auth for token)
  sl.registerLazySingleton<SpotifyApiDatasource>(
    () => SpotifyApiDatasource(
      getAccessToken: () {
        // This will be called for each request
        // In production, we'd get the token from SpotifyAuthDatasource
        // For now, return empty (will be set when authenticated)
        return '';
      },
    ),
  );

  // Player Service
  sl.registerLazySingleton<PlayerService>(() => PlayerService());

  // ============== BLOCS ==============

  // Auth BLoC - singleton (maintains auth state)
  sl.registerLazySingleton<AuthBloc>(
    () => AuthBloc(
      firebaseAuth: sl<FirebaseAuth>(),
      spotifyAuth: sl<SpotifyAuthDatasource>(),
      deepLinkHandler: sl<DeepLinkHandler>(),
    ),
  );

  // Player BLoC - singleton (maintains playback state)
  sl.registerLazySingleton<PlayerBloc>(
    () => PlayerBloc(playerService: sl<PlayerService>()),
  );

  // Initialize deep link handling
  await DeepLinkService.initialize();
}

/// Reset all dependencies (for testing)
Future<void> resetDependencies() async {
  await sl.reset();
}

/// Get a registered dependency
T get<T extends Object>() => sl<T>();

/// Check if a dependency is registered
bool isRegistered<T extends Object>() => sl.isRegistered<T>();
