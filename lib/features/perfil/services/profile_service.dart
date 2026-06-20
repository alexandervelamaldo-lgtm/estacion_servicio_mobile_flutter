import '../../../core/network/api_client.dart';
import '../models/user_profile_model.dart';

class ProfileService {
  ProfileService(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/usuarios/me/
  Future<UserProfile> getProfile() async {
    final response = await _apiClient.get(
      '/usuarios/me/',
      authenticated: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Respuesta del servidor inválida.');
    }

    return UserProfile.fromJson(response);
  }

  /// PATCH /api/usuarios/me/
  Future<UserProfile> updateProfile(Map<String, dynamic> data) async {
    final response = await _apiClient.patch(
      '/usuarios/me/',
      body: data,
      authenticated: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Respuesta del servidor inválida.');
    }

    return UserProfile.fromJson(response);
  }
}
