import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:app_links/app_links.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:async';
import 'firebase_options.dart';
import 'screens/home_screen.dart';
import 'screens/login_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  runApp(const VibeApp());
}

class VibeApp extends StatefulWidget {
  const VibeApp({super.key});
  @override
  State<VibeApp> createState() => _VibeAppState();
}

class _VibeAppState extends State<VibeApp> {
  late AppLinks _appLinks;
  StreamSubscription? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _initDeepLinks();
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  Future<void> _initDeepLinks() async {
    _appLinks = AppLinks();

    // Проверка при запуске - ИСПРАВЛЕНО!
    try {
      final initialUri = await _appLinks.getInitialAppLink();
      if (initialUri != null) {
        _handleUri(initialUri);
      }
    } catch (e) {
      debugPrint('Initial URI error: $e');
    }

    // Слушаем новые ссылки - ИСПРАВЛЕНО!
    _linkSubscription = _appLinks.allUriLinkStream.listen(
          (Uri uri) {
        _handleUri(uri);
      },
      onError: (err) {
        debugPrint('Deep link error: $err');
      },
    );
  }

  Future<void> _handleUri(Uri uri) async {
    debugPrint('📲 Received URI: $uri');

    if (uri.scheme == 'vibe' && uri.host == 'spotify-callback') {
      final code = uri.queryParameters['code'];
      if (code != null) {
        debugPrint('✅ Spotify Code received: ${code.substring(0, 10)}...');
        await _exchangeCodeForToken(code);
      } else {
        debugPrint('❌ No code in callback');
      }
    }
  }

  Future<void> _exchangeCodeForToken(String code) async {
    const clientId = '0c4284170a4f4c68a4834dc317e6bd11';
    const redirectUri = 'vibe://spotify-callback';

    try {
      debugPrint('🔄 Exchanging code for token...');

      final response = await http.post(
        Uri.parse('https://accounts.spotify.com/api/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': code,
          'redirect_uri': redirectUri,
          'client_id': clientId,
        },
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final accessToken = data['access_token'];
        final refreshToken = data['refresh_token'];

        debugPrint('✅ Tokens received');

        // Анонимный вход в Firebase
        final userCred = await FirebaseAuth.instance.signInAnonymously();
        debugPrint('✅ Firebase anonymous login');

        // Сохраняем токены
        await FirebaseFirestore.instance
            .collection('users')
            .doc(userCred.user!.uid)
            .set({
          'spotify_access_token': accessToken,
          'spotify_refresh_token': refreshToken,
          'token_expires_at': DateTime.now().add(const Duration(hours: 1)),
          'last_login': FieldValue.serverTimestamp(),
        }, SetOptions(merge: true));

        debugPrint('✅ Tokens saved to Firestore');

        if (mounted) {
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(builder: (_) => const HomeScreen()),
          );
        }
      } else {
        debugPrint('❌ Token exchange failed: ${response.statusCode}');
        debugPrint('Response: ${response.body}');

        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Ошибка входа: ${response.statusCode}')),
          );
        }
      }
    } catch (e) {
      debugPrint('❌ Exception during token exchange: $e');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Ошибка: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Vibe',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple,
        scaffoldBackgroundColor: const Color(0xFF121212),
        useMaterial3: true,
      ),
      home: const AuthWrapper(),
    );
  }
}

class AuthWrapper extends StatelessWidget {
  const AuthWrapper({super.key});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<User?>(
      stream: FirebaseAuth.instance.authStateChanges(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Scaffold(
            body: Center(child: CircularProgressIndicator()),
          );
        }

        if (snapshot.hasData) {
          return const HomeScreen();
        }

        return const LoginScreen();
      },
    );
  }
}