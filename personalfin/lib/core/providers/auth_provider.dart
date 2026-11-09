import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const sessionStorage = FlutterSecureStorage();

class AuthSession {
  const AuthSession({
    this.accessToken,
    this.refreshToken,
    this.userId,
    this.userName,
    this.phone,
  });

  final String? accessToken;
  final String? refreshToken;
  final String? userId;
  final String? userName;
  final String? phone;

  bool get isAuthenticated => accessToken != null && accessToken!.isNotEmpty;

  AuthSession copyWith({
    String? accessToken,
    String? refreshToken,
    String? userId,
    String? userName,
    String? phone,
  }) {
    return AuthSession(
      accessToken: accessToken ?? this.accessToken,
      refreshToken: refreshToken ?? this.refreshToken,
      userId: userId ?? this.userId,
      userName: userName ?? this.userName,
      phone: phone ?? this.phone,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthSession> {
  AuthNotifier() : super(const AuthSession()) {
    ready = _restoreSession();
  }

  late final Future<void> ready;

  Future<void> _restoreSession() async {
    try {
      final values = await Future.wait([
        sessionStorage.read(key: 'accessToken'),
        sessionStorage.read(key: 'refreshToken'),
        sessionStorage.read(key: 'userId'),
        sessionStorage.read(key: 'userName'),
        sessionStorage.read(key: 'phone'),
      ]);
      if (values[0] == null || values[1] == null) return;
      state = AuthSession(
        accessToken: values[0],
        refreshToken: values[1],
        userId: values[2],
        userName: values[3],
        phone: values[4],
      );
    } catch (_) {
      state = const AuthSession();
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required String userId,
    required String userName,
    required String phone,
  }) async {
    await Future.wait([
      sessionStorage.write(key: 'accessToken', value: accessToken),
      sessionStorage.write(key: 'refreshToken', value: refreshToken),
      sessionStorage.write(key: 'userId', value: userId),
      sessionStorage.write(key: 'userName', value: userName),
      sessionStorage.write(key: 'phone', value: phone),
    ]);
    state = AuthSession(
      accessToken: accessToken,
      refreshToken: refreshToken,
      userId: userId,
      userName: userName,
      phone: phone,
    );
  }

  void updateTokens(String accessToken, String refreshToken) {
    state = state.copyWith(accessToken: accessToken, refreshToken: refreshToken);
  }

  Future<void> clearSession() async {
    await Future.wait([
      sessionStorage.delete(key: 'accessToken'),
      sessionStorage.delete(key: 'refreshToken'),
      sessionStorage.delete(key: 'userId'),
      sessionStorage.delete(key: 'userName'),
      sessionStorage.delete(key: 'phone'),
    ]);
    state = const AuthSession();
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthSession>((ref) {
  return AuthNotifier();
});
