import '../../../core/network/api_client.dart';
import '../models/fuel_catalog_item.dart';
import '../models/purchase.dart';

class PurchaseService {
  PurchaseService(this._apiClient);

  final ApiClient _apiClient;

  Future<List<FuelCatalogItem>> getCatalog() async {
    final response = await _apiClient.get('/tipos-combustible/');
    final items = response as List<dynamic>;
    return items
        .map((item) => FuelCatalogItem.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<List<Purchase>> getPurchases() async {
    final response = await _apiClient.get('/compras/', authenticated: true);

    if (response is List<dynamic>) {
      return response
          .map((item) => Purchase.fromJson(item as Map<String, dynamic>))
          .toList();
    }

    final results = (response as Map<String, dynamic>)['results'] as List<dynamic>? ?? const [];
    return results
        .map((item) => Purchase.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<Purchase> createPurchase({
    required String tipoCombustible,
    required String cantidad,
    required String observacion,
  }) async {
    final response = await _apiClient.post(
      '/compras/',
      authenticated: true,
      body: {
        'tipo_combustible': tipoCombustible,
        'cantidad': cantidad,
        'observacion': observacion.trim(),
      },
    ) as Map<String, dynamic>;

    return Purchase.fromJson(response);
  }
}
