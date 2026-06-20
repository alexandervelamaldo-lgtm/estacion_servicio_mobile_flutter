import 'package:flutter/material.dart';
import '../../../core/network/api_client.dart';
import '../models/tanque.dart';
import '../services/inventario_service.dart';

class InventarioController extends ChangeNotifier {
  InventarioController(this._service);

  final InventarioService _service;

  List<Tanque> _tanques = [];
  bool _loading = false;
  bool _procesando = false;
  String? _errorMessage;
  String? _successMessage;

  List<Tanque> get tanques => _tanques;
  bool get loading => _loading;
  bool get procesando => _procesando;
  String? get errorMessage => _errorMessage;
  String? get successMessage => _successMessage;

  Future<void> cargar() async {
    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _tanques = await _service.getTanques();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar inventario.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  Future<bool> registrarDescarga({
    required int tanqueId,
    required double volumen,
    String observaciones = '',
  }) async {
    _procesando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _service.registrarDescarga(
        tanqueId: tanqueId,
        volumen: volumen,
        observaciones: observaciones,
      );
      _successMessage = result['mensaje'] as String?;
      await cargar();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }

  Future<bool> ampliarCapacidad({
    required int tanqueId,
    required double nuevaCapacidad,
  }) async {
    _procesando = true;
    _errorMessage = null;
    _successMessage = null;
    notifyListeners();

    try {
      final result = await _service.ampliarCapacidad(
        tanqueId: tanqueId,
        nuevaCapacidad: nuevaCapacidad,
      );
      _successMessage = result['mensaje'] as String?;
      await cargar();
      return true;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } finally {
      _procesando = false;
      notifyListeners();
    }
  }
}