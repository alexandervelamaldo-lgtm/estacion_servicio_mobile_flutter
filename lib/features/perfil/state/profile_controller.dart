import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';
import '../services/profile_service.dart';

class ProfileController extends ChangeNotifier {
  ProfileController(this._profileService);

  final ProfileService _profileService;

  UserProfile? _profile;
  bool _loading = false;
  bool _saving = false;
  String? _errorMessage;
  String? _successMessage;

  UserProfile? get profile => _profile;
  bool get loading => _loading;
  bool get saving => _saving;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  void clearMessages() {
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();
  }

  Future<void> loadProfile() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.getProfile();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar el perfil.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> updateProfile(Map<String, dynamic> data) async {
    _saving = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      _profile = await _profileService.updateProfile(data);
      _successMessage = 'Perfil actualizado correctamente.';
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (e) {
      _errorMessage = 'Error inesperado al actualizar el perfil.';
      return false;
    } finally {
      _saving = false;
      notifyListeners();
    }
  }
}
