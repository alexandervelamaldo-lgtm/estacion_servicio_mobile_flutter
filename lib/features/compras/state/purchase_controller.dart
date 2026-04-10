import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/fuel_catalog_item.dart';
import '../models/purchase.dart';
import '../services/purchase_service.dart';

class PurchaseController extends ChangeNotifier {
  PurchaseController(this._purchaseService);

  final PurchaseService _purchaseService;

  List<FuelCatalogItem> _catalog = const [];
  List<Purchase> _purchases = const [];
  bool _loadingCatalog = false;
  bool _loadingHistory = false;
  bool _submitting = false;
  String? _errorMessage;

  List<FuelCatalogItem> get catalog => _catalog;
  List<Purchase> get purchases => _purchases;
  bool get loadingCatalog => _loadingCatalog;
  bool get loadingHistory => _loadingHistory;
  bool get submitting => _submitting;
  String? get errorMessage => _errorMessage;

  Future<void> loadCatalog({bool force = false}) async {
    if (_catalog.isNotEmpty && !force) {
      return;
    }

    _loadingCatalog = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _catalog = await _purchaseService.getCatalog();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No se pudo cargar el catálogo de combustibles.';
    } finally {
      _loadingCatalog = false;
      notifyListeners();
    }
  }

  Future<void> loadPurchases() async {
    _loadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _purchases = await _purchaseService.getPurchases();
    } on ApiException catch (error) {
      _errorMessage = error.message;
    } catch (_) {
      _errorMessage = 'No se pudo cargar el historial de compras.';
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  Future<bool> registerPurchase({
    required String tipoCombustible,
    required String cantidad,
    required String observacion,
  }) async {
    _submitting = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final purchase = await _purchaseService.createPurchase(
        tipoCombustible: tipoCombustible,
        cantidad: cantidad,
        observacion: observacion,
      );
      _purchases = [purchase, ..._purchases];
      return true;
    } on ApiException catch (error) {
      _errorMessage = error.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo registrar la compra.';
      return false;
    } finally {
      _submitting = false;
      notifyListeners();
    }
  }

  FuelCatalogItem? findByCode(String code) {
    for (final item in _catalog) {
      if (item.codigo == code) {
        return item;
      }
    }
    return _catalog.isNotEmpty ? _catalog.first : null;
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
