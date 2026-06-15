import 'package:flutter/foundation.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../constants/app_constants.dart';

class StoredTokens {
  const StoredTokens({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresAtMs,
  });

  final String accessToken;
  final String refreshToken;
  final int expiresAtMs;

  bool get isAccessTokenValid {
    final now = DateTime.now().millisecondsSinceEpoch;
    final skew = AppConstants.accessTokenSkewSeconds * 1000;
    return expiresAtMs - skew > now;
  }
}

abstract class TokenStorage {
  Future<StoredTokens?> read();

  Future<String?> readAccessToken();

  Future<String?> readRefreshToken();

  Future<void> write({
    required String accessToken,
    required String refreshToken,
    required int expiresInMs,
  });

  Future<void> clear();
}

class SecureTokenStorage implements TokenStorage {
  SecureTokenStorage(this._storage);

  final FlutterSecureStorage _storage;

  static const _accessTokenKey = 'vfit.accessToken';
  static const _refreshTokenKey = 'vfit.refreshToken';
  static const _expiresAtKey = 'vfit.expiresAtMs';

  @override
  Future<StoredTokens?> read() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      final accessToken = prefs.getString(_accessTokenKey);
      final refreshToken = prefs.getString(_refreshTokenKey);
      final expiresAtRaw = prefs.getString(_expiresAtKey);
      final expiresAtMs = int.tryParse(expiresAtRaw ?? '');
      if (accessToken == null || refreshToken == null || expiresAtMs == null) {
        return null;
      }
      return StoredTokens(
        accessToken: accessToken,
        refreshToken: refreshToken,
        expiresAtMs: expiresAtMs,
      );
    }

    final accessToken = await _storage.read(key: _accessTokenKey);
    final refreshToken = await _storage.read(key: _refreshTokenKey);
    final expiresAtRaw = await _storage.read(key: _expiresAtKey);
    final expiresAtMs = int.tryParse(expiresAtRaw ?? '');
    if (accessToken == null || refreshToken == null || expiresAtMs == null) {
      return null;
    }
    return StoredTokens(
      accessToken: accessToken,
      refreshToken: refreshToken,
      expiresAtMs: expiresAtMs,
    );
  }

  @override
  Future<String?> readAccessToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_accessTokenKey);
    }
    return _storage.read(key: _accessTokenKey);
  }

  @override
  Future<String?> readRefreshToken() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getString(_refreshTokenKey);
    }
    return _storage.read(key: _refreshTokenKey);
  }

  @override
  Future<void> write({
    required String accessToken,
    required String refreshToken,
    required int expiresInMs,
  }) async {
    final expiresAtMs = DateTime.now().millisecondsSinceEpoch + expiresInMs;
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString(_accessTokenKey, accessToken);
      await prefs.setString(_refreshTokenKey, refreshToken);
      await prefs.setString(_expiresAtKey, expiresAtMs.toString());
      return;
    }
    await _storage.write(key: _accessTokenKey, value: accessToken);
    await _storage.write(key: _refreshTokenKey, value: refreshToken);
    await _storage.write(key: _expiresAtKey, value: expiresAtMs.toString());
  }

  @override
  Future<void> clear() async {
    if (kIsWeb) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove(_accessTokenKey);
      await prefs.remove(_refreshTokenKey);
      await prefs.remove(_expiresAtKey);
      return;
    }
    await _storage.delete(key: _accessTokenKey);
    await _storage.delete(key: _refreshTokenKey);
    await _storage.delete(key: _expiresAtKey);
  }
}
