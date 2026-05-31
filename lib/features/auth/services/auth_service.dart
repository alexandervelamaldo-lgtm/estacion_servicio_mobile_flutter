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

class RegisterResult {
  const RegisterResult({
    required this.message,
    required this.verificationRequired,
    this.verificationUrl,
  });

  final String message;
  final bool verificationRequired;
  final String? verificationUrl;
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

  Future<RegisterResult> register({
    required String nombre,
    required String email,
    required String password,
    required String passwordConfirmacion,
    required bool aceptaPoliticaPrivacidad,
  }) async {
    final response = await _apiClient.post(
        '/auth/register/',
      body: {
        'nombre': nombre.trim(),
        'email': email.trim().toLowerCase(),
        'password': password,
        'password_confirmacion': passwordConfirmacion,
        'acepta_politica_privacidad': aceptaPoliticaPrivacidad,
      },
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Respuesta del servidor inválida.');
    }

    return RegisterResult(
      message: response['mensaje'] as String? ?? 'Cuenta creada correctamente.',
      verificationRequired: response['verification_required'] as bool? ?? false,
      verificationUrl: response['verification_url'] as String?,
    );
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
  final userMap = json['user'];

  if (accessToken is! String || accessToken.isEmpty) {
    throw ApiException('No se recibió el token de acceso.');
  }
  if (refreshToken is! String || refreshToken.isEmpty) {
    throw ApiException('No se recibió el token de refresh.');
  }
  if (userMap is! Map<String, dynamic>) {
    throw ApiException('No se recibió la información del usuario.');
  }

  return LoginResult(
    user: AuthUser.fromJson(userMap),
    accessToken: accessToken,
    refreshToken: refreshToken,
  );
}
}
