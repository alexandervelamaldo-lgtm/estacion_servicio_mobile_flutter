import '../../../core/network/api_client.dart';

/// Servicio que consume los endpoints de reportes del backend.
class ReportesService {
  ReportesService(this._apiClient);

  final ApiClient _apiClient;

  /// Obtiene reporte de ventas con los filtros proporcionados.
  Future<Map<String, dynamic>> getVentas({
    Map<String, dynamic> filtros = const {},
  }) async {
    return _fetchReporte('/reportes/ventas/', filtros);
  }

  /// Obtiene reporte de turnos con los filtros proporcionados.
  Future<Map<String, dynamic>> getTurnos({
    Map<String, dynamic> filtros = const {},
  }) async {
    return _fetchReporte('/reportes/turnos/', filtros);
  }

  /// Obtiene reporte de clientes con los filtros proporcionados.
  Future<Map<String, dynamic>> getClientes({
    Map<String, dynamic> filtros = const {},
  }) async {
    return _fetchReporte('/reportes/clientes/', filtros);
  }

  /// Obtiene reporte de sucursales con los filtros proporcionados.
  Future<Map<String, dynamic>> getSucursales({
    Map<String, dynamic> filtros = const {},
  }) async {
    return _fetchReporte('/reportes/sucursales/', filtros);
  }

  /// Obtiene reporte de islas con los filtros proporcionados.
  Future<Map<String, dynamic>> getIslas({
    Map<String, dynamic> filtros = const {},
  }) async {
    return _fetchReporte('/reportes/islas/', filtros);
  }

  /// Construye la query string y hace GET al endpoint correspondiente.
  Future<Map<String, dynamic>> _fetchReporte(
    String path,
    Map<String, dynamic> filtros,
  ) async {
    final queryParts = <String>[];
    filtros.forEach((key, value) {
      if (value != null && value.toString().isNotEmpty) {
        queryParts.add('$key=${Uri.encodeComponent(value.toString())}');
      }
    });

    final fullPath = queryParts.isEmpty ? path : '$path?${queryParts.join('&')}';

    final response = await _apiClient.get(fullPath, authenticated: true);

    if (response is Map<String, dynamic>) {
      return response;
    }

    // Si el backend devuelve una lista directa, la envolvemos.
    if (response is List) {
      return {'results': response};
    }

    throw ApiException('Respuesta inesperada del servidor.');
  }
}
