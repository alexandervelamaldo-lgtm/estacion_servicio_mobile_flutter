import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:http/http.dart' as http;

import '../config/app_config.dart';
import '../storage/session_storage.dart';

class ApiException implements Exception {
  ApiException(this.message, {this.statusCode});

  final String message;
  final int? statusCode;

  @override
  String toString() => message;
}

class ApiClient {
  ApiClient(this._sessionStorage);

  final SessionStorage _sessionStorage;
  static const Duration _requestTimeout = Duration(seconds: 20);

  Uri _uri(String path) => Uri.parse('${AppConfig.baseUrl}$path');

  Future<Map<String, String>> _headers({bool authenticated = false}) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };

    if (authenticated) {
      final token = await _sessionStorage.getAccessToken();
      if (token != null && token.isNotEmpty) {
        headers['Authorization'] = 'Bearer $token';
      }
    }

    return headers;
  }

  Future<dynamic> get(String path, {bool authenticated = false}) async {
    try {
      final response = await http
          .get(
            _uri(path),
            headers: await _headers(authenticated: authenticated),
          )
          .timeout(_requestTimeout);
      return _handleResponse(response, retryPath: path, retryMethod: 'GET', authenticated: authenticated);
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado. Verifica tu conexión y que el backend esté levantado.');
    } on SocketException {
      throw ApiException('No se pudo conectar al servidor. Verifica que el backend esté levantado (${AppConfig.baseUrl}).');
    } on HandshakeException {
      throw ApiException('No se pudo establecer una conexión segura con el servidor.');
    }
  }

  Future<dynamic> post(
    String path, {
    Map<String, dynamic>? body,
    bool authenticated = false,
  }) async {
    try {
      final response = await http
          .post(
            _uri(path),
            headers: await _headers(authenticated: authenticated),
            body: jsonEncode(body ?? <String, dynamic>{}),
          )
          .timeout(_requestTimeout);
      return _handleResponse(
        response,
        retryPath: path,
        retryMethod: 'POST',
        retryBody: body,
        authenticated: authenticated,
      );
    } on TimeoutException {
      throw ApiException('Tiempo de espera agotado. Verifica tu conexión y que el backend esté levantado.');
    } on SocketException {
      throw ApiException('No se pudo conectar al servidor. Verifica que el backend esté levantado (${AppConfig.baseUrl}).');
    } on HandshakeException {
      throw ApiException('No se pudo establecer una conexión segura con el servidor.');
    }
  }

  Future<dynamic> _handleResponse(
    http.Response response, {
    required String retryPath,
    required String retryMethod,
    Map<String, dynamic>? retryBody,
    required bool authenticated,
  }) async {
    if (response.statusCode == 401 && authenticated) {
      final refreshed = await _refreshToken();
      if (refreshed) {
        if (retryMethod == 'GET') {
          return get(retryPath, authenticated: true);
        }
        return post(retryPath, body: retryBody, authenticated: true);
      }
    }

    if (response.body.isEmpty) {
      if (response.statusCode >= 200 && response.statusCode < 300) {
        return null;
      }
      throw ApiException('La respuesta del servidor llegó vacía.', statusCode: response.statusCode);
    }

    final contentType = response.headers['content-type'] ?? '';
    final isJsonResponse = contentType.contains('application/json');
    if (!isJsonResponse) {
      final url = _uri(retryPath).toString();
      if (response.statusCode >= 200 && response.statusCode < 300) {
        throw ApiException('Respuesta inesperada del servidor (no es JSON) desde $url.', statusCode: response.statusCode);
      }
      throw ApiException('Solicitud fallida (HTTP ${response.statusCode}) en $url.', statusCode: response.statusCode);
    }

    dynamic decoded;
    try {
      decoded = jsonDecode(utf8.decode(response.bodyBytes));
    } on FormatException {
      final statusLabel = response.statusCode.toString();
      throw ApiException('Respuesta del servidor con formato inesperado (HTTP $statusLabel).', statusCode: response.statusCode);
    }
    if (response.statusCode >= 200 && response.statusCode < 300) {
      return decoded;
    }

    if (decoded is Map<String, dynamic>) {
      final detail = decoded['detail'] ?? decoded['error'];
      if (detail is String && detail.isNotEmpty) {
        throw ApiException(detail, statusCode: response.statusCode);
      }

      final firstValue = decoded.values.isNotEmpty ? decoded.values.first : null;
      if (firstValue is List && firstValue.isNotEmpty) {
        throw ApiException(firstValue.first.toString(), statusCode: response.statusCode);
      }
    }

    throw ApiException('No se pudo completar la solicitud.', statusCode: response.statusCode);
  }

  Future<bool> _refreshToken() async {
    final refreshToken = await _sessionStorage.getRefreshToken();
    if (refreshToken == null || refreshToken.isEmpty) {
      await _sessionStorage.clear();
      return false;
    }

    final response = await http.post(
      _uri('/token/refresh/'),
      headers: await _headers(),
      body: jsonEncode({'refresh': refreshToken}),
    );

    if (response.statusCode < 200 || response.statusCode >= 300) {
      await _sessionStorage.clear();
      return false;
    }

    final decoded = jsonDecode(response.body) as Map<String, dynamic>;
    final access = decoded['access'] as String?;
    if (access == null || access.isEmpty) {
      await _sessionStorage.clear();
      return false;
    }

    await _sessionStorage.updateAccessToken(access);
    return true;
  }
}
