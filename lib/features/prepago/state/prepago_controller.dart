import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../../core/config/app_config.dart';
import '../../../core/network/api_client.dart';
import '../../compras/models/fuel_catalog_item.dart';
import '../models/prepago_orden.dart';
import '../services/prepago_service.dart';

class PrepagoController extends ChangeNotifier {
  PrepagoController(this._service);

  final PrepagoService _service;

  // ─── Catálogo ───
  List<FuelCatalogItem> _combustibles = const [];
  List<FuelCatalogItem> get combustibles => _combustibles;

  // ─── Selección del usuario ───
  FuelCatalogItem? _selectedCombustible;
  FuelCatalogItem? get selectedCombustible => _selectedCombustible;

  double _montoIngresado = 0;
  double get montoIngresado => _montoIngresado;

  double get litrosEstimados {
    if (_selectedCombustible == null ||
        _selectedCombustible!.precioUnitario <= 0 ||
        _montoIngresado <= 0) {
      return 0;
    }
    return _montoIngresado / _selectedCombustible!.precioUnitario;
  }

  // ─── Estado Wizard ───
  int _currentStep = 0;
  int get currentStep => _currentStep;

  bool _isLoading = false;
  bool get isLoading => _isLoading;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  // ─── Resultado de la orden ───
  String? _clientSecret;
  int? _ordenId;
  String? _numeroOrden;

  int? get ordenId => _ordenId;
  String? get numeroOrden => _numeroOrden;

  bool _pagoExitoso = false;
  bool get pagoExitoso => _pagoExitoso;

  // ─── Historial ───
  List<PrepagoOrden> _ordenes = const [];
  List<PrepagoOrden> get ordenes => _ordenes;

  bool _loadingHistory = false;
  bool get loadingHistory => _loadingHistory;

  // ─── Acciones Catálogo ───

  Future<void> loadCombustibles({bool force = false}) async {
    if (_combustibles.isNotEmpty && !force) return;

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _combustibles = await _service.getCombustibles();
      if (_combustibles.isNotEmpty && _selectedCombustible == null) {
        _selectedCombustible = _combustibles.first;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No se pudo cargar los combustibles.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  void selectCombustible(FuelCatalogItem item) {
    _selectedCombustible = item;
    notifyListeners();
  }

  void setMonto(double monto) {
    _montoIngresado = monto;
    notifyListeners();
  }

  // ─── Navegación Wizard ───

  void goToStep(int step) {
    _currentStep = step;
    notifyListeners();
  }

  void nextStep() {
    _currentStep++;
    notifyListeners();
  }

  void previousStep() {
    if (_currentStep > 0) {
      _currentStep--;
      notifyListeners();
    }
  }

  // ─── Crear Orden ───

  Future<bool> crearOrden() async {
    if (_selectedCombustible == null || _montoIngresado <= 0) {
      _errorMessage = 'Selecciona un combustible e ingresa un monto válido.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      // El backend espera un ID numérico para tipo_combustible_id.
      // FuelCatalogItem usa "codigo" como string, pero necesitamos
      // intentar buscar un id numérico. Usamos el índice + 1 o
      // intentamos parsear el código como int.
      final catalogIndex = _combustibles.indexOf(_selectedCombustible!);
      final tipoCombustibleId =
          int.tryParse(_selectedCombustible!.codigo) ?? (catalogIndex + 1);

      final response = await _service.crearOrden(
        tipoCombustibleId: tipoCombustibleId,
        montoTotal: _montoIngresado,
      );

      _clientSecret = response['client_secret'] as String?;
      _ordenId = response['orden_id'] as int?;
      _numeroOrden = response['numero_orden'] as String?;

      return _clientSecret != null && _clientSecret!.isNotEmpty;
    } on ApiException catch (e) {
      _errorMessage = e.message;
      return false;
    } catch (_) {
      _errorMessage = 'No se pudo crear la orden prepago.';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Confirmar Pago Stripe (Payment Sheet) ───

  Future<bool> confirmarPagoStripe() async {
    if (_clientSecret == null || _clientSecret!.isEmpty) {
      _errorMessage = 'No se encontró el secreto del pago. Intenta de nuevo.';
      notifyListeners();
      return false;
    }

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      debugPrint('[Stripe] clientSecret: ${_clientSecret!.substring(0, 20)}...');
      debugPrint('[Stripe] Initializing Payment Sheet...');

      // 1. Inicializar el Payment Sheet
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: _clientSecret!,
          merchantDisplayName: 'SurtidorBolivia',
          style: ThemeMode.light,
        ),
      );

      debugPrint('[Stripe] Payment Sheet initialized. Presenting...');

      // 2. Presentar el Payment Sheet al usuario
      await Stripe.instance.presentPaymentSheet();

      // Si llegamos aquí, el pago fue exitoso
      _pagoExitoso = true;
      _currentStep = 2; // Paso de confirmación
      return true;
    } on StripeException catch (e) {
      debugPrint('[Stripe] StripeException: ${e.error.code} - ${e.error.localizedMessage} - ${e.error.message}');
      if (e.error.code == FailureCode.Canceled) {
        // El usuario canceló el pago, no es un error
        _errorMessage = null;
      } else {
        _errorMessage =
            e.error.localizedMessage ?? 'El pago no se pudo completar.';
      }
      return false;
    } catch (e) {
      debugPrint('[Stripe] Error genérico: $e');
      _errorMessage = 'Error: $e';
      return false;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Historial ───

  Future<void> loadOrdenes() async {
    _loadingHistory = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _ordenes = await _service.misOrdenes();
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No se pudo cargar el historial prepago.';
    } finally {
      _loadingHistory = false;
      notifyListeners();
    }
  }

  // ─── Descargar PDF ───

  Future<void> descargarYCompartirPdf(int ordenId) async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final bytes = await _service.descargarPdf(ordenId);
      final dir = await getTemporaryDirectory();
      final file = File('${dir.path}/Comprobante_Surtidor_$ordenId.pdf');
      await file.writeAsBytes(bytes);
      
      // Compartir o abrir el archivo
      await Share.shareXFiles([XFile(file.path)], text: 'Comprobante de Pago Prepago #$ordenId');
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No se pudo descargar el comprobante.';
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  // ─── Reset Wizard ───

  void resetWizard() {
    _currentStep = 0;
    _montoIngresado = 0;
    _selectedCombustible =
        _combustibles.isNotEmpty ? _combustibles.first : null;
    _clientSecret = null;
    _ordenId = null;
    _numeroOrden = null;
    _pagoExitoso = false;
    _errorMessage = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
