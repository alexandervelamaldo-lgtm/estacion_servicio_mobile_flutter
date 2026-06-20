import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/sucursal_monitoreo.dart';
import '../services/monitoreo_service.dart';

class MonitoreoController extends ChangeNotifier {
  MonitoreoController(this._service);

  final MonitoreoService _service;

  List<SucursalMonitoreo> _sucursales = [];
  bool _loading = false;
  bool _cambiando = false;
  String? _errorMessage;

  List<SucursalMonitoreo> get sucursales => _sucursales;
  bool get loading => _loading;
  bool get cambiando => _cambiando;
  String? get errorMessage => _errorMessage;

  Future<void> cargar() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _sucursales = await _service.getSucursales();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar monitoreo.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> cambiarEstado({
    required int ladoId,
    required String estado,
    String descripcion = '',
  }) async {
    _cambiando = true;
    _errorMessage = null;
    notifyListeners();

    try {
      await _service.cambiarEstado(
        ladoId: ladoId,
        estado: estado,
        descripcion: descripcion,
      );
      await cargar();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _cambiando = false;
      notifyListeners();
    }
  }
}