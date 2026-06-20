import 'package:flutter/material.dart';

import '../../../core/network/api_client.dart';
import '../models/dashboard_model.dart';
import '../services/dashboard_service.dart';

class DashboardController extends ChangeNotifier {
  DashboardController(this._dashboardService);

  final DashboardService _dashboardService;

  DashboardData? _data;
  bool _loading = false;
  String? _errorMessage;
  String? _fechaInicio;
  String? _fechaFin;

  DashboardData? get data => _data;
  bool get loading => _loading;
  String? get errorMessage => _errorMessage;
  String? get fechaInicio => _fechaInicio;
  String? get fechaFin => _fechaFin;

  Future<void> loadKpis({bool force = false}) async {
    if (_data != null && !force) return;

    _loading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _data = await _dashboardService.getKpis(
        fechaInicio: _fechaInicio,
        fechaFin: _fechaFin,
      );
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (e) {
      _errorMessage = 'Error inesperado al cargar el dashboard.';
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  void setFechas({String? fechaInicio, String? fechaFin}) {
    _fechaInicio = fechaInicio;
    _fechaFin = fechaFin;
    loadKpis(force: true);
  }

  void clearFiltros() {
    _fechaInicio = null;
    _fechaFin = null;
    loadKpis(force: true);
  }
}
