import '../../../core/network/api_client.dart';
import '../models/sucursal_monitoreo.dart';

class MonitoreoService {
  MonitoreoService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<SucursalMonitoreo>> getSucursales() async {
    final response = await _apiClient.get(
      '/monitoreo/surtidores/',
      authenticated: true,
    );
    final list = response as List<dynamic>;
    return list
        .map((e) => SucursalMonitoreo.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  Future<void> cambiarEstado({
    required int ladoId,
    required String estado,
    String descripcion = '',
  }) async {
    await _apiClient.post(
      '/monitoreo/surtidores/cambiar_estado/',
      authenticated: true,
      body: {
        'lado_id': ladoId,
        'estado': estado,
        'descripcion': descripcion,
      },
    );
  }

  Future<List<Map<String, dynamic>>> getHistorial() async {
    final response = await _apiClient.get(
      '/monitoreo/surtidores/historial/',
      authenticated: true,
    );
    return (response as List<dynamic>)
        .cast<Map<String, dynamic>>();
  }
}