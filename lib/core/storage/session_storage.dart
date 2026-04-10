import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import '../../features/auth/models/auth_user.dart';

class SessionStorage {
  static const _accessTokenKey = 'access_token';
  static const _refreshTokenKey = 'refresh_token';
  static const _userKey = 'user';
  static String? _memoryAccessToken;
  static String? _memoryRefreshToken;
  static String? _memoryUserJson;

  Future<SharedPreferences?> _preferencesOrNull() async {
    try {
      return await SharedPreferences.getInstance();
    } catch (_) {
      return null;
    }
  }

  Future<void> saveSession({
    required String accessToken,
    required String refreshToken,
    required AuthUser user,
  }) async {
    final userJson = jsonEncode(user.toJson());
    final preferences = await _preferencesOrNull();
    if (preferences == null) {
      _memoryAccessToken = accessToken;
      _memoryRefreshToken = refreshToken;
      _memoryUserJson = userJson;
      return;
    }
    await preferences.setString(_accessTokenKey, accessToken);
    await preferences.setString(_refreshTokenKey, refreshToken);
    await preferences.setString(_userKey, userJson);
  }

  Future<void> updateAccessToken(String accessToken) async {
    final preferences = await _preferencesOrNull();
    if (preferences == null) {
      _memoryAccessToken = accessToken;
      return;
    }
    await preferences.setString(_accessTokenKey, accessToken);
  }

  Future<String?> getAccessToken() async {
    final preferences = await _preferencesOrNull();
    if (preferences == null) {
      return _memoryAccessToken;
    }
    return preferences.getString(_accessTokenKey);
  }

  Future<String?> getRefreshToken() async {
    final preferences = await _preferencesOrNull();
    if (preferences == null) {
      return _memoryRefreshToken;
    }
    return preferences.getString(_refreshTokenKey);
  }

  Future<AuthUser?> getUser() async {
    final preferences = await _preferencesOrNull();
    final rawUser = preferences == null ? _memoryUserJson : preferences.getString(_userKey);

    if (rawUser == null || rawUser.isEmpty) {
      return null;
    }

    return AuthUser.fromJson(jsonDecode(rawUser) as Map<String, dynamic>);
  }

  Future<bool> hasSession() async {
    final accessToken = await getAccessToken();
    return accessToken != null && accessToken.isNotEmpty;
  }

  Future<void> clear() async {
    _memoryAccessToken = null;
    _memoryRefreshToken = null;
    _memoryUserJson = null;

    final preferences = await _preferencesOrNull();
    if (preferences == null) {
      return;
    }
    await preferences.remove(_accessTokenKey);
    await preferences.remove(_refreshTokenKey);
    await preferences.remove(_userKey);
  }
}
