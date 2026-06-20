import '../../../core/network/api_client.dart';
import '../models/tanque.dart';

class InventarioService {
  InventarioService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<Tanque>> getTanques() async {
    final response = await _apiClient.get(
      '/inventario/tanques/',
      authenticated: true,
    );
    final list = response is List
        ? response
        : (response as Map<String, dynamic>)['results'] as List;
    return list
        .map((e) => Tanque.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<Map<String, dynamic>> registrarDescarga({
    required int tanqueId,
    required double volumen,
    String observaciones = '',
  }) async {
    final response = await _apiClient.post(
      '/inventario/tanques/$tanqueId/registrar_descarga/',
      authenticated: true,
      body: {
        'volumen_descargado': volumen,
        'observaciones': observaciones,
      },
    );
    return response as Map<String, dynamic>;
  }

  Future<Map<String, dynamic>> ampliarCapacidad({
    required int tanqueId,
    required double nuevaCapacidad,
  }) async {
    final response = await _apiClient.post(
      '/inventario/tanques/$tanqueId/ampliar_capacidad/',
      authenticated: true,
      body: {'capacidad_maxima': nuevaCapacidad},
    );
    return response as Map<String, dynamic>;
  }
}