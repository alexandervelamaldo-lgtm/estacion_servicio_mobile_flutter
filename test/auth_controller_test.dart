import 'package:estacion_servicio_mobile_flutter/core/network/api_client.dart';
import 'package:estacion_servicio_mobile_flutter/core/storage/session_storage.dart';
import 'package:estacion_servicio_mobile_flutter/features/auth/models/auth_user.dart';
import 'package:estacion_servicio_mobile_flutter/features/auth/services/auth_service.dart';
import 'package:estacion_servicio_mobile_flutter/features/auth/state/auth_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakeAuthService extends AuthService {
  FakeAuthService() : super(ApiClient(SessionStorage()), SessionStorage());

  Object? registerError;
  RegisterResult registerResult = const RegisterResult(
    message: 'Cuenta creada. Revisa tu correo para verificarla.',
    verificationRequired: true,
  );

  @override
  Future<LoginResult> login({
    required String email,
    required String password,
  }) {
    throw UnimplementedError();
  }

  @override
  Future<RegisterResult> register({
    required String nombre,
    required String email,
    required String password,
    required String passwordConfirmacion,
    required bool aceptaPoliticaPrivacidad,
  }) async {
    if (registerError != null) {
      throw registerError!;
    }
    return registerResult;
  }

  @override
  Future<void> persistSession(LoginResult result) async {}

  @override
  Future<void> logout() async {}

  @override
  Future<AuthUser?> restoreUser() async => null;

  @override
  Future<bool> hasSession() async => false;
}

void main() {
  test('registro exitoso deja mensaje informativo y no autentica automaticamente', () async {
    final authService = FakeAuthService();
    final controller = AuthController(authService);

    final success = await controller.register(
      nombre: 'Fer',
      email: 'fer@example.com',
      password: 'ClaveSegura123!',
      passwordConfirmacion: 'ClaveSegura123!',
      aceptaPoliticaPrivacidad: true,
    );

    expect(success, isTrue);
    expect(controller.infoMessage, contains('Revisa tu correo'));
    expect(controller.isAuthenticated, isFalse);
  });

  test('registro muestra error de conexion cuando el servicio falla', () async {
    final authService = FakeAuthService();
    authService.registerError = ApiException('No se pudo conectar al servidor.');
    final controller = AuthController(authService);

    final success = await controller.register(
      nombre: 'Fer',
      email: 'fer@example.com',
      password: 'ClaveSegura123!',
      passwordConfirmacion: 'ClaveSegura123!',
      aceptaPoliticaPrivacidad: true,
    );

    expect(success, isFalse);
    expect(controller.errorMessage, contains('No se pudo conectar'));
  });
}
