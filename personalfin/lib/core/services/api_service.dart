import 'dart:async';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter/foundation.dart';
import '../providers/auth_provider.dart';

const _configuredApiBaseUrl = String.fromEnvironment('API_BASE_URL');

String _apiBaseUrl() {
  if (_configuredApiBaseUrl.isNotEmpty) {
    final uri = Uri.tryParse(_configuredApiBaseUrl);
    if (uri == null || !uri.hasAuthority || !uri.hasScheme) {
      throw StateError('API_BASE_URL must be an absolute URL.');
    }
    if (kReleaseMode && uri.scheme != 'https') {
      throw StateError('API_BASE_URL must use HTTPS in release builds.');
    }
    return _configuredApiBaseUrl;
  }
  if (kReleaseMode) {
    throw StateError('Set API_BASE_URL to the deployed HTTPS API before building a release.');
  }
  return 'http://localhost:3000/api/v1';
}

class ApiService {
  ApiService({
    void Function(String accessToken, String refreshToken)? onTokensRefreshed,
    void Function()? onSessionExpired,
  })
      : _dio = Dio(
          BaseOptions(
            baseUrl: _apiBaseUrl(),
            connectTimeout: const Duration(seconds: 12),
            receiveTimeout: const Duration(seconds: 12),
            headers: {
              'Content-Type': 'application/json',
            },
          ),
        ) {
    _dio.interceptors.add(InterceptorsWrapper(
      onRequest: (options, handler) async {
        if (options.headers.containsKey('Authorization')) {
          final token = await sessionStorage.read(key: 'accessToken');
          if (token != null) options.headers['Authorization'] = 'Bearer $token';
        }
        handler.next(options);
      },
      onError: (error, handler) async {
        final options = error.requestOptions;
        final hasAuthHeader = options.headers.containsKey('Authorization');
        if (error.response?.statusCode != 401 ||
            !hasAuthHeader ||
            options.path.endsWith('/auth/refresh') ||
            options.extra['retriedAfterRefresh'] == true) {
          handler.next(error);
          return;
        }

        final token = await _refreshAccessToken(onTokensRefreshed);
        if (token == null) {
          onSessionExpired?.call();
          handler.next(error);
          return;
        }

        options.headers['Authorization'] = 'Bearer $token';
        options.extra['retriedAfterRefresh'] = true;
        try {
          handler.resolve(await _dio.fetch<dynamic>(options));
        } on DioException catch (retryError) {
          handler.next(retryError);
        }
      },
    ));
  }

  final Dio _dio;
  Future<String?>? _refreshing;

  Future<String?> _refreshAccessToken(
    void Function(String accessToken, String refreshToken)? onTokensRefreshed,
  ) {
    return _refreshing ??= _performRefresh(onTokensRefreshed).whenComplete(() {
      _refreshing = null;
    });
  }

  Future<String?> _performRefresh(
    void Function(String accessToken, String refreshToken)? onTokensRefreshed,
  ) async {
    try {
      final refreshToken = await sessionStorage.read(key: 'refreshToken');
      if (refreshToken == null) return null;
      final response = await _dio.post<Map<String, dynamic>>(
        '/auth/refresh',
        data: {'refreshToken': refreshToken},
      );
      final access = response.data?['accessToken'] as String?;
      final refresh = response.data?['refreshToken'] as String?;
      if (access == null || refresh == null) return null;
      await Future.wait([
        sessionStorage.write(key: 'accessToken', value: access),
        sessionStorage.write(key: 'refreshToken', value: refresh),
      ]);
      onTokensRefreshed?.call(access, refresh);
      return access;
    } catch (_) {
      return null;
    }
  }

  Future<Map<String, dynamic>> requestOtp({required String phone}) async {
    final response = await _dio.post(
      '/auth/otp/request',
      data: {'phone': phone},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> verifyOtp({required String phone, required String code}) async {
    final response = await _dio.post(
      '/auth/otp/verify',
      data: {'phone': phone, 'code': code},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> signInWithGoogle({required String idToken}) async {
    final response = await _dio.post(
      '/auth/google',
      data: {'idToken': idToken},
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<void> logout({required String accessToken, required String refreshToken}) async {
    await _dio.post<void>(
      '/auth/logout',
      data: {'refreshToken': refreshToken},
      options: Options(headers: {'Authorization': 'Bearer $accessToken'}),
    );
  }

  Future<Map<String, dynamic>> generatePlan({
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post(
      '/plan/generate',
      data: payload,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getCurrentPlan({required String accessToken}) async {
    final response = await _dio.get(
      '/plan/current',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getProfile({required String accessToken}) async {
    final response = await _dio.get(
      '/profile',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getMe({required String accessToken}) async {
    final response = await _dio.get(
      '/auth/me',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> sendAdvisorMessage({
    required String accessToken,
    required List<Map<String, String>> messages,
  }) async {
    final response = await _dio.post(
      '/advisor/chat',
      data: {'messages': messages},
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getTransactions({required String accessToken}) async {
    final response = await _dio.get(
      '/transactions',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createTransaction({
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post(
      '/transactions',
      data: payload,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> getGoals({required String accessToken}) async {
    final response = await _dio.get(
      '/goals',
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }

  Future<Map<String, dynamic>> createGoal({
    required String accessToken,
    required Map<String, dynamic> payload,
  }) async {
    final response = await _dio.post(
      '/goals',
      data: payload,
      options: Options(
        headers: {'Authorization': 'Bearer $accessToken'},
      ),
    );

    return Map<String, dynamic>.from(response.data as Map);
  }
}

final apiServiceProvider = Provider<ApiService>((ref) => ApiService(
      onTokensRefreshed: ref.read(authProvider.notifier).updateTokens,
      onSessionExpired: () => unawaited(ref.read(authProvider.notifier).clearSession()),
    ));
