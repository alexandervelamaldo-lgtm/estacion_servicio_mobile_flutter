import '../../../core/network/api_client.dart';
import '../../compras/models/fuel_catalog_item.dart';
import '../models/prepago_orden.dart';

class PrepagoService {
  PrepagoService(this._apiClient);

  final ApiClient _apiClient;

  /// GET /api/precios-combustible/
  /// Reutiliza el catálogo de combustibles existente.
  Future<List<FuelCatalogItem>> getCombustibles() async {
    final response = await _apiClient.get('/precios-combustible/');
    final items = response as List<dynamic>;
    return items
        .map((item) => FuelCatalogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// POST /api/prepago/crear/
  /// Crea una orden prepago y retorna el client_secret para Stripe + datos de la orden.
  Future<Map<String, dynamic>> crearOrden({
    required int tipoCombustibleId,
    required double montoTotal,
  }) async {
    final response = await _apiClient.post(
      '/prepago/crear/',
      authenticated: true,
      body: {
        'tipo_combustible_id': tipoCombustibleId,
        'monto_total': montoTotal,
      },
    ) as Map<String, dynamic>;
    return response;
  }

  /// GET /api/prepago/mis-ordenes/
  /// Lista el historial de órdenes prepago del usuario.
  Future<List<PrepagoOrden>> misOrdenes() async {
    final response =
        await _apiClient.get('/prepago/mis-ordenes/', authenticated: true);

    List<dynamic> items;
    if (response is List<dynamic>) {
      items = response;
    } else {
      items = (response as Map<String, dynamic>)['results']
              as List<dynamic>? ??
          const [];
    }

    return items
        .map((item) => PrepagoOrden.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  /// GET /api/prepago/{ordenId}/pdf/
  /// Descarga el comprobante PDF de una orden prepago.
  Future<List<int>> descargarPdf(int ordenId) async {
    return _apiClient.downloadBytes(
      '/prepago/$ordenId/pdf/',
      authenticated: true,
    );
  }
}
