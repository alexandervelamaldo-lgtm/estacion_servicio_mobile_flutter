import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../../../core/network/api_client.dart';
import '../models/auth_user.dart';
import '../services/auth_service.dart';

class AuthController extends ChangeNotifier {
  AuthController(this._authService);

  final AuthService _authService;

  AuthUser? _user;
  bool _loading = true;
  bool _submitting = false;
  String? _errorMessage;
  String? _infoMessage;

  AuthUser? get user => _user;
  bool get loading => _loading;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;
  String? get infoMessage => _infoMessage;
  bool get isAuthenticated => _user != null;

  Future<void> bootstrap() async {
    _loading = true;
    notifyListeners();

    final hasSession = await _authService.hasSession();
    if (hasSession) {
      _user = await _authService.restoreUser();
    } else {
      _user = null;
    }

    _loading = false;
    notifyListeners();
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    return _runAuthAction(() async {
      final result = await _authService.login(email: email, password: password);
      await _authService.persistSession(result);
      _user = result.user;
    });
  }

  Future<bool> register({
    required String nombre,
    required String email,
    required String password,
    required String passwordConfirmacion,
    required bool aceptaPoliticaPrivacidad,
  }) async {
    return _runAuthAction(() async {
      final result = await _authService.register(
        nombre: nombre,
        email: email,
        password: password,
        passwordConfirmacion: passwordConfirmacion,
        aceptaPoliticaPrivacidad: aceptaPoliticaPrivacidad,
      );
      _infoMessage = result.message;
    });
  }

  Future<void> logout() async {
    _submitting = true;
    notifyListeners();

    await _authService.logout();
    _user = null;
    _submitting = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();
  }

  Future<bool> _runAuthAction(Future<void> Function() action) async {
    _submitting = true;
    _errorMessage = null;
    _infoMessage = null;
    notifyListeners();

    try {
      await action();
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (error) {
      _errorMessage = _formatUnexpectedError(error);
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  String _formatUnexpectedError(Object error) {
    if (error is MissingPluginException) {
      return 'Error interno del dispositivo. Reinstala la app y vuelve a intentar.';
    }
    if (error is FormatException) {
      return 'Respuesta del servidor con formato inesperado. Verifica la URL del backend.';
    }
    return 'Ocurrió un problema inesperado (${error.runtimeType}).';
  }
}
