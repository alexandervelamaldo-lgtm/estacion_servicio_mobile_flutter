import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';

class DashboardService {
  DashboardService(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/dashboard/kpis/?fecha_inicio=...&fecha_fin=...
  Future<DashboardData> getKpis({
    String? fechaInicio,
    String? fechaFin,
  }) async {
    final queryParams = <String, String>{};
    if (fechaInicio != null && fechaInicio.isNotEmpty) {
      queryParams['fecha_inicio'] = fechaInicio;
    }
    if (fechaFin != null && fechaFin.isNotEmpty) {
      queryParams['fecha_fin'] = fechaFin;
    }

    final queryString = queryParams.entries
        .map((e) => '${e.key}=${e.value}')
        .join('&');
    final path = queryString.isEmpty
        ? '/dashboard/kpis/'
        : '/dashboard/kpis/?$queryString';

    final response = await _apiClient.get(
      path,
      authenticated: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Respuesta del servidor inválida.');
    }

    return DashboardData.fromJson(response);
  }
}
