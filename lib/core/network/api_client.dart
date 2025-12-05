/// HTTP API Client with automatic token management and error handling
///
/// This provides a wrapper around HTTP requests with:
/// - Automatic token injection
/// - Token refresh on 401
/// - Retry logic with exponential backoff
/// - Standardized error handling

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../errors/exceptions.dart';

/// Configuration for API client
class ApiClientConfig {
  final String baseUrl;
  final Duration timeout;
  final int maxRetries;
  final Duration retryDelay;

  const ApiClientConfig({
    required this.baseUrl,
    this.timeout = const Duration(seconds: 30),
    this.maxRetries = 3,
    this.retryDelay = const Duration(seconds: 1),
  });
}

/// Interface for providing authentication tokens
abstract class TokenProvider {
  Future<String?> getAccessToken();
  Future<String?> refreshToken();
  Future<void> clearTokens();
}

/// HTTP API Client with automatic token handling
class ApiClient {
  final ApiClientConfig config;
  final TokenProvider? tokenProvider;
  final http.Client _httpClient;

  ApiClient({
    required this.config,
    this.tokenProvider,
    http.Client? httpClient,
  }) : _httpClient = httpClient ?? http.Client();

  /// Performs a GET request
  Future<Map<String, dynamic>> get(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);
    return _executeWithRetry(
      () => _httpClient.get(uri, headers: requestHeaders),
      requiresAuth: requiresAuth,
    );
  }

  /// Performs a POST request
  Future<Map<String, dynamic>> post(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = true,
    bool isFormEncoded = false,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);

    if (isFormEncoded) {
      requestHeaders['Content-Type'] = 'application/x-www-form-urlencoded';
    } else {
      requestHeaders['Content-Type'] = 'application/json';
    }

    return _executeWithRetry(
      () => _httpClient.post(
        uri,
        headers: requestHeaders,
        body: isFormEncoded ? body : (body != null ? jsonEncode(body) : null),
      ),
      requiresAuth: requiresAuth,
    );
  }

  /// Performs a PUT request
  Future<Map<String, dynamic>> put(
    String path, {
    Map<String, dynamic>? body,
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);
    requestHeaders['Content-Type'] = 'application/json';
    return _executeWithRetry(
      () => _httpClient.put(
        uri,
        headers: requestHeaders,
        body: body != null ? jsonEncode(body) : null,
      ),
      requiresAuth: requiresAuth,
    );
  }

  /// Performs a DELETE request
  Future<Map<String, dynamic>> delete(
    String path, {
    Map<String, String>? queryParams,
    Map<String, String>? headers,
    bool requiresAuth = true,
  }) async {
    final uri = _buildUri(path, queryParams);
    final requestHeaders = await _buildHeaders(headers, requiresAuth);
    return _executeWithRetry(
      () => _httpClient.delete(uri, headers: requestHeaders),
      requiresAuth: requiresAuth,
    );
  }

  /// Builds the full URI for a request
  Uri _buildUri(String path, Map<String, String>? queryParams) {
    final baseUri = Uri.parse(config.baseUrl);
    return Uri(
      scheme: baseUri.scheme,
      host: baseUri.host,
      port: baseUri.port,
      path: '${baseUri.path}$path',
      queryParameters: queryParams?.isNotEmpty == true ? queryParams : null,
    );
  }

  /// Builds request headers with optional authentication
  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? customHeaders,
    bool requiresAuth,
  ) async {
    final headers = <String, String>{
      'Accept': 'application/json',
      ...?customHeaders,
    };

    if (requiresAuth && tokenProvider != null) {
      final token = await tokenProvider!.getAccessToken();
      if (token != null) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  /// Executes a request with retry logic and token refresh
  Future<Map<String, dynamic>> _executeWithRetry(
    Future<http.Response> Function() request, {
    bool requiresAuth = true,
    int attempt = 0,
  }) async {
    try {
      final response = await request().timeout(config.timeout);

      // Handle 401 - attempt token refresh
      if (response.statusCode == 401 && requiresAuth && attempt == 0) {
        if (tokenProvider != null) {
          final newToken = await tokenProvider!.refreshToken();
          if (newToken != null) {
            debugPrint('Token refreshed, retrying request...');
            return _executeWithRetry(
              request,
              requiresAuth: requiresAuth,
              attempt: attempt + 1,
            );
          }
        }
        throw AuthException.tokenExpired();
      }

      // Handle rate limiting with retry
      if (response.statusCode == 429 && attempt < config.maxRetries) {
        final retryAfter = _parseRetryAfter(response.headers);
        await Future.delayed(retryAfter);
        return _executeWithRetry(
          request,
          requiresAuth: requiresAuth,
          attempt: attempt + 1,
        );
      }

      // Handle other errors
      if (response.statusCode >= 400) {
        throw NetworkException.fromStatusCode(response.statusCode, response.body);
      }

      // Parse successful response
      if (response.body.isEmpty) {
        return {};
      }

      try {
        return jsonDecode(response.body) as Map<String, dynamic>;
      } catch (e) {
        // Return raw body in a wrapper if not JSON
        return {'_raw': response.body};
      }
    } on SocketException {
      throw NetworkException.noConnection();
    } on TimeoutException {
      if (attempt < config.maxRetries) {
        await Future.delayed(config.retryDelay * (attempt + 1));
        return _executeWithRetry(
          request,
          requiresAuth: requiresAuth,
          attempt: attempt + 1,
        );
      }
      throw NetworkException.timeout();
    }
  }

  /// Parses the Retry-After header for rate limiting
  Duration _parseRetryAfter(Map<String, String> headers) {
    final retryAfter = headers['retry-after'];
    if (retryAfter != null) {
      final seconds = int.tryParse(retryAfter);
      if (seconds != null) {
        return Duration(seconds: seconds);
      }
    }
    return const Duration(seconds: 5);
  }

  /// Closes the HTTP client
  void close() {
    _httpClient.close();
  }
}

/// Spotify-specific API client with Spotify base URL
class SpotifyApiClient extends ApiClient {
  SpotifyApiClient({
    required TokenProvider tokenProvider,
    http.Client? httpClient,
  }) : super(
          config: const ApiClientConfig(
            baseUrl: 'https://api.spotify.com/v1',
            timeout: Duration(seconds: 30),
            maxRetries: 3,
          ),
          tokenProvider: tokenProvider,
          httpClient: httpClient,
        );
}

/// Spotify Accounts API client for authentication
class SpotifyAccountsClient extends ApiClient {
  SpotifyAccountsClient({
    http.Client? httpClient,
  }) : super(
          config: const ApiClientConfig(
            baseUrl: 'https://accounts.spotify.com',
            timeout: Duration(seconds: 30),
            maxRetries: 2,
          ),
          httpClient: httpClient,
        );

  /// Exchange authorization code for tokens
  Future<Map<String, dynamic>> exchangeCode({
    required String code,
    required String redirectUri,
    required String codeVerifier,
    required String clientId,
  }) async {
    return post(
      '/api/token',
      body: {
        'grant_type': 'authorization_code',
        'code': code,
        'redirect_uri': redirectUri,
        'client_id': clientId,
        'code_verifier': codeVerifier,
      },
      requiresAuth: false,
      isFormEncoded: true,
    );
  }

  /// Refresh access token
  Future<Map<String, dynamic>> refreshAccessToken({
    required String refreshToken,
    required String clientId,
  }) async {
    return post(
      '/api/token',
      body: {
        'grant_type': 'refresh_token',
        'refresh_token': refreshToken,
        'client_id': clientId,
      },
      requiresAuth: false,
      isFormEncoded: true,
    );
  }

  /// Get client credentials token (for non-user-specific API calls)
  Future<Map<String, dynamic>> getClientCredentialsToken({
    required String clientId,
    required String clientSecret,
  }) async {
    final credentials = base64Encode(utf8.encode('$clientId:$clientSecret'));

    return post(
      '/api/token',
      body: {'grant_type': 'client_credentials'},
      headers: {'Authorization': 'Basic $credentials'},
      requiresAuth: false,
      isFormEncoded: true,
    );
  }
}
