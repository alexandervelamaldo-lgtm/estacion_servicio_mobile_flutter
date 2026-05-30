import 'dart:io';

import 'package:excel/excel.dart' as xl;
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:path_provider/path_provider.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:share_plus/share_plus.dart';

import '../../../core/network/api_client.dart';
import '../services/reportes_service.dart';
import '../services/voice_service.dart';

/// Pestañas disponibles en la pantalla de reportes.
enum ReporteTab { ventas, turnos, clientes, sucursales, islas }

/// Controller que gestiona el estado completo de la pantalla de reportes,
/// incluyendo la carga de datos, filtros, exportación y el asistente de voz.
class ReportesController extends ChangeNotifier {
  ReportesController(this._reportesService, this._voiceService);

  final ReportesService _reportesService;
  final VoiceService _voiceService;

  // ── Estado de datos ──────────────────────────────────────────────────

  ReporteTab _activeTab = ReporteTab.ventas;
  ReporteTab get activeTab => _activeTab;

  Map<String, dynamic> _currentData = const {};
  Map<String, dynamic> get currentData => _currentData;

  bool _loadingData = false;
  bool get loadingData => _loadingData;

  String? _errorMessage;
  String? get errorMessage => _errorMessage;

  Map<String, dynamic> _filtros = {};
  Map<String, dynamic> get filtros => _filtros;

  // ── Estado de voz ────────────────────────────────────────────────────

  VoiceState _voiceState = VoiceState.idle;
  VoiceState get voiceState => _voiceState;

  String _recognizedText = '';
  String get recognizedText => _recognizedText;

  String? _voiceError;
  String? get voiceError => _voiceError;

  VoiceCommandResult? _lastVoiceResult;
  VoiceCommandResult? get lastVoiceResult => _lastVoiceResult;

  // ── Tab / Filtros ────────────────────────────────────────────────────

  void setTab(ReporteTab tab) {
    if (_activeTab == tab) return;
    _activeTab = tab;
    _currentData = const {};
    notifyListeners();
    loadReporte();
  }

  void setFiltros(Map<String, dynamic> nuevosFiltros) {
    _filtros = nuevosFiltros;
    notifyListeners();
    loadReporte();
  }

  void clearFiltros() {
    _filtros = {};
    notifyListeners();
    loadReporte();
  }

  // ── Carga de datos ───────────────────────────────────────────────────

  Future<void> loadReporte() async {
    _loadingData = true;
    _errorMessage = null;
    notifyListeners();

    try {
      switch (_activeTab) {
        case ReporteTab.ventas:
          _currentData = await _reportesService.getVentas(filtros: _filtros);
          break;
        case ReporteTab.turnos:
          _currentData = await _reportesService.getTurnos(filtros: _filtros);
          break;
        case ReporteTab.clientes:
          _currentData = await _reportesService.getClientes(filtros: _filtros);
          break;
        case ReporteTab.sucursales:
          _currentData = await _reportesService.getSucursales(filtros: _filtros);
          break;
        case ReporteTab.islas:
          _currentData = await _reportesService.getIslas(filtros: _filtros);
          break;
      }
    } on ApiException catch (e) {
      _errorMessage = e.message;
    } catch (_) {
      _errorMessage = 'No se pudo cargar el reporte.';
    } finally {
      _loadingData = false;
      notifyListeners();
    }
  }

  // ── Asistente de voz ─────────────────────────────────────────────────

  Future<bool> initVoice() async {
    return _voiceService.initialize();
  }

  Future<void> startListening() async {
    _voiceState = VoiceState.listening;
    _recognizedText = '';
    _voiceError = null;
    notifyListeners();

    try {
      await _voiceService.startListening(
        onResult: (text, isFinal) {
          _recognizedText = text;
          notifyListeners();

          if (isFinal && text.trim().isNotEmpty) {
            _processVoiceCommand(text.trim());
          }
        },
        onDone: () {
          if (_voiceState == VoiceState.listening && _recognizedText.trim().isNotEmpty) {
            _processVoiceCommand(_recognizedText.trim());
          } else if (_voiceState == VoiceState.listening) {
            _voiceState = VoiceState.error;
            _voiceError = 'No se escuchó nada. Inténtelo de nuevo.';
            notifyListeners();
          }
        },
      );
    } on ApiException catch (e) {
      _voiceState = VoiceState.error;
      _voiceError = e.message;
      notifyListeners();
    } catch (_) {
      _voiceState = VoiceState.error;
      _voiceError = 'Error al iniciar el reconocimiento de voz.';
      notifyListeners();
    }
  }

  Future<void> stopListening() async {
    await _voiceService.stopListening();
  }

  Future<void> _processVoiceCommand(String texto) async {
    _voiceState = VoiceState.processing;
    notifyListeners();

    try {
      final result = await _voiceService.interpretarComando(texto);
      _lastVoiceResult = result;

      // Aplicar el resultado.
      final tab = _tabFromString(result.tipoReporte);
      _activeTab = tab;
      _filtros = result.filtros;

      _voiceState = VoiceState.success;
      notifyListeners();

      // Cargar el reporte con los filtros interpretados.
      await loadReporte();
      
      // Exportar a PDF automáticamente por defecto, tal como lo hace la versión web.
      await exportToPdf();
    } on ApiException catch (e) {
      _voiceState = VoiceState.error;
      _voiceError = e.message;
      notifyListeners();
    } catch (e, stackTrace) {
      print('Error al procesar comando de voz: $e');
      print(stackTrace);
      _voiceState = VoiceState.error;
      _voiceError = 'Error inesperado: $e';
      notifyListeners();
    }
  }

  void resetVoice() {
    _voiceState = VoiceState.idle;
    _recognizedText = '';
    _voiceError = null;
    _lastVoiceResult = null;
    notifyListeners();
  }

  ReporteTab _tabFromString(String tipo) {
    switch (tipo.toLowerCase()) {
      case 'turnos':
        return ReporteTab.turnos;
      case 'clientes':
        return ReporteTab.clientes;
      case 'sucursales':
        return ReporteTab.sucursales;
      case 'islas':
        return ReporteTab.islas;
      default:
        return ReporteTab.ventas;
    }
  }

  // ── Exportación ──────────────────────────────────────────────────────

  List<Map<String, dynamic>> _extractRows() {
    final data = _currentData;
    if (data.containsKey('results') && data['results'] is List) {
      return (data['results'] as List).cast<Map<String, dynamic>>();
    }
    if (data.containsKey('data') && data['data'] is List) {
      return (data['data'] as List).cast<Map<String, dynamic>>();
    }
    final keys = ['turnos', 'por_combustible', 'ranking_clientes', 'ventas', 'clientes', 'sucursales', 'islas'];
    for (final key in keys) {
      if (data.containsKey(key) && data[key] is List) {
        return (data[key] as List).cast<Map<String, dynamic>>();
      }
    }
    // Fallback: Retornar la primera lista que se encuentre en el JSON
    for (final value in data.values) {
      if (value is List) {
        return value.cast<Map<String, dynamic>>();
      }
    }
    return [];
  }

  Future<void> exportToExcel() async {
    final rows = _extractRows();
    if (rows.isEmpty) return;

    final excel = xl.Excel.createExcel();
    final sheet = excel['Reporte'];

    // Header
    final headers = rows.first.keys.toList();
    sheet.appendRow(headers.map((h) => xl.TextCellValue(h)).toList());

    // Data
    for (final row in rows) {
      sheet.appendRow(
        headers.map((h) => xl.TextCellValue(row[h]?.toString() ?? '')).toList(),
      );
    }

    // Eliminar la hoja por defecto si existe.
    if (excel.sheets.containsKey('Sheet1')) {
      excel.delete('Sheet1');
    }

    final bytes = excel.encode();
    if (bytes == null) return;

    await _shareFile(bytes, 'reporte_${_activeTab.name}.xlsx');
  }

  Future<void> exportToPdf() async {
    final rows = _extractRows();
    if (rows.isEmpty) return;

    final headers = rows.first.keys.toList();
    final doc = pw.Document();

    doc.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4.landscape,
        header: (context) => pw.Text(
          'Reporte de ${_activeTab.name.toUpperCase()} – ${DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now())}',
          style: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 14),
        ),
        build: (context) => [
          pw.TableHelper.fromTextArray(
            headers: headers,
            data: rows.map((r) => headers.map((h) => r[h]?.toString() ?? '').toList()).toList(),
            headerStyle: pw.TextStyle(fontWeight: pw.FontWeight.bold, fontSize: 8),
            cellStyle: const pw.TextStyle(fontSize: 7),
            cellAlignment: pw.Alignment.centerLeft,
          ),
        ],
      ),
    );

    final bytes = await doc.save();
    await _shareFile(bytes, 'reporte_${_activeTab.name}.pdf');
  }

  Future<void> exportToHtml() async {
    final rows = _extractRows();
    if (rows.isEmpty) return;

    final headers = rows.first.keys.toList();
    final buf = StringBuffer();
    buf.writeln('<!DOCTYPE html><html><head><meta charset="utf-8">');
    buf.writeln('<title>Reporte ${_activeTab.name}</title>');
    buf.writeln('<style>');
    buf.writeln('body{font-family:sans-serif;padding:20px}');
    buf.writeln('table{border-collapse:collapse;width:100%}');
    buf.writeln('th,td{border:1px solid #ddd;padding:8px;text-align:left}');
    buf.writeln('th{background:#081327;color:#fff}');
    buf.writeln('tr:nth-child(even){background:#f9f9f9}');
    buf.writeln('</style></head><body>');
    buf.writeln('<h1>Reporte de ${_activeTab.name}</h1>');
    buf.writeln('<table><thead><tr>');
    for (final h in headers) {
      buf.writeln('<th>$h</th>');
    }
    buf.writeln('</tr></thead><tbody>');
    for (final row in rows) {
      buf.writeln('<tr>');
      for (final h in headers) {
        buf.writeln('<td>${row[h] ?? ''}</td>');
      }
      buf.writeln('</tr>');
    }
    buf.writeln('</tbody></table></body></html>');

    final bytes = buf.toString().codeUnits;
    await _shareFile(bytes, 'reporte_${_activeTab.name}.html');
  }

  Future<void> _shareFile(List<int> bytes, String fileName) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/$fileName');
    await file.writeAsBytes(bytes);

    await Share.shareXFiles(
      [XFile(file.path)],
      subject: 'Reporte - SurtidorBolivia',
    );
  }
}
