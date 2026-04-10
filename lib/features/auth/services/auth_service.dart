import '../../../core/network/api_client.dart';
import '../../../core/storage/session_storage.dart';
import '../models/auth_user.dart';

class LoginResult {
  const LoginResult({
    required this.user,
    required this.accessToken,
    required this.refreshToken,
  });

  final AuthUser user;
  final String accessToken;
  final String refreshToken;
}

class AuthService {
  AuthService(this._apiClient, this._sessionStorage);

  final ApiClient _apiClient;
  final SessionStorage _sessionStorage;

  Future<LoginResult> login({
    required String email,
    required String password,
  }) async {
    final response = await _apiClient.post(
      '/auth/login/',
      body: {'email': email.trim(), 'password': password},
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Respuesta del servidor inválida.');
    }

    return _buildLoginResult(response);
  }

  Future<LoginResult> register({
    required String nombre,
    required String email,
    required String password,
    required String passwordConfirmacion,
  }) async {
    await _apiClient.post(
      '/auth/register/',
      body: {
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmacion': passwordConfirmacion,
      },
    );

    return login(email: email, password: password);
  }

  Future<void> persistSession(LoginResult result) async {
    await _sessionStorage.saveSession(
      accessToken: result.accessToken,
      refreshToken: result.refreshToken,
      user: result.user,
    );
  }

  Future<void> logout() async {
    try {
      await _apiClient.post('/auth/logout/', authenticated: true);
    } catch (_) {}
    await _sessionStorage.clear();
  }

  Future<AuthUser?> restoreUser() {
    return _sessionStorage.getUser();
  }

  Future<bool> hasSession() {
    return _sessionStorage.hasSession();
  }

  LoginResult _buildLoginResult(Map<String, dynamic> json) {
    final accessToken = json['access'];
    final refreshToken = json['refresh'];
    final user = json['user'];

    if (accessToken is! String || accessToken.isEmpty) {
      throw ApiException('No se recibió el token de acceso.');
    }
    if (refreshToken is! String || refreshToken.isEmpty) {
      throw ApiException('No se recibió el token de refresh.');
    }
    if (user is! Map<String, dynamic>) {
      throw ApiException('No se recibió la información del usuario.');
    }

    return LoginResult(
      user: AuthUser.fromJson(user),
      accessToken: accessToken,
      refreshToken: refreshToken,
    );
  }
}
