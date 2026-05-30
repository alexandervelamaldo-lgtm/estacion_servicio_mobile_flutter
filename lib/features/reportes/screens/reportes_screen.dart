import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../state/reportes_controller.dart';
import '../widgets/voice_assistant_modal.dart';

/// Pantalla principal de Reportes e Inteligencia.
/// Incluye pestañas (Ventas, Turnos, Clientes, Sucursales, Islas),
/// filtros de fecha, tabla de datos y opciones de exportación.
class ReportesScreen extends StatefulWidget {
  const ReportesScreen({super.key});

  @override
  State<ReportesScreen> createState() => _ReportesScreenState();
}

class _ReportesScreenState extends State<ReportesScreen> {
  final _fechaInicioCtrl = TextEditingController();
  final _fechaFinCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ReportesController>().loadReporte();
    });
  }

  @override
  void dispose() {
    _fechaInicioCtrl.dispose();
    _fechaFinCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportesController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Reportes e Inteligencia'),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.file_download_outlined),
            tooltip: 'Exportar',
            onSelected: (value) => _handleExport(value, controller),
            itemBuilder: (_) => [
              const PopupMenuItem(value: 'excel', child: Text('Exportar a Excel')),
              const PopupMenuItem(value: 'pdf', child: Text('Exportar a PDF')),
              const PopupMenuItem(value: 'html', child: Text('Exportar a HTML')),
            ],
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _openVoiceAssistant(controller),
        backgroundColor: AppTheme.secondary,
        icon: const Icon(Icons.mic_rounded, color: Colors.white),
        label: const Text('Asistente', style: TextStyle(color: Colors.white, fontWeight: FontWeight.w700)),
      ),
      body: Column(
        children: [
          // Tabs
          _buildTabBar(controller),

          // Filters
          _buildFilterBar(controller),

          // Content
          Expanded(child: _buildContent(controller)),
        ],
      ),
    );
  }

  // ── Tab Bar ──────────────────────────────────────────────────────────

  Widget _buildTabBar(ReportesController controller) {
    return Container(
      color: AppTheme.primary,
      child: Row(
        children: ReporteTab.values.map((tab) {
          final isActive = controller.activeTab == tab;
          return Expanded(
            child: InkWell(
              onTap: () => controller.setTab(tab),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 14),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: isActive ? AppTheme.secondary : Colors.transparent,
                      width: 3,
                    ),
                  ),
                ),
                child: Text(
                  _tabLabel(tab),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: isActive ? Colors.white : Colors.white60,
                    fontWeight: isActive ? FontWeight.w700 : FontWeight.w500,
                    fontSize: 13,
                  ),
                ),
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _tabLabel(ReporteTab tab) {
    switch (tab) {
      case ReporteTab.ventas:
        return 'Ventas';
      case ReporteTab.turnos:
        return 'Turnos';
      case ReporteTab.clientes:
        return 'Clientes';
      case ReporteTab.sucursales:
        return 'Sucursales';
      case ReporteTab.islas:
        return 'Islas';
    }
  }

  // ── Filter Bar ───────────────────────────────────────────────────────

  Widget _buildFilterBar(ReportesController controller) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: _fechaInicioCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Fecha inicio',
                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onTap: () => _pickDate(context, _fechaInicioCtrl),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: _fechaFinCtrl,
              readOnly: true,
              decoration: const InputDecoration(
                hintText: 'Fecha fin',
                prefixIcon: Icon(Icons.calendar_today_rounded, size: 18),
                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              ),
              onTap: () => _pickDate(context, _fechaFinCtrl),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: () {
              controller.setFiltros({
                if (_fechaInicioCtrl.text.isNotEmpty) 'fecha_inicio': _fechaInicioCtrl.text,
                if (_fechaFinCtrl.text.isNotEmpty) 'fecha_fin': _fechaFinCtrl.text,
              });
            },
            icon: const Icon(Icons.search_rounded),
            style: IconButton.styleFrom(backgroundColor: AppTheme.primary),
          ),
          IconButton(
            onPressed: () {
              _fechaInicioCtrl.clear();
              _fechaFinCtrl.clear();
              controller.clearFiltros();
            },
            icon: const Icon(Icons.clear_rounded),
            tooltip: 'Limpiar filtros',
          ),
        ],
      ),
    );
  }

  Future<void> _pickDate(BuildContext context, TextEditingController ctrl) async {
    final now = DateTime.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: now,
      firstDate: DateTime(2020),
      lastDate: now.add(const Duration(days: 1)),
    );
    if (picked != null) {
      ctrl.text = DateFormat('yyyy-MM-dd').format(picked);
    }
  }

  // ── Content ──────────────────────────────────────────────────────────

  Widget _buildContent(ReportesController controller) {
    if (controller.loadingData) {
      return const Center(child: CircularProgressIndicator());
    }

    if (controller.errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
              const SizedBox(height: 12),
              Text(
                controller.errorMessage!,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: controller.loadReporte,
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    final rows = _extractRows(controller.currentData);
    if (rows.isEmpty) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.inbox_rounded, size: 48, color: Colors.grey.shade400),
            const SizedBox(height: 12),
            Text(
              'No hay datos para mostrar.',
              style: Theme.of(context).textTheme.bodyLarge?.copyWith(color: Colors.grey),
            ),
            const SizedBox(height: 8),
            Text(
              'Intenta ajustar los filtros o usa el asistente de voz.',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
            ),
          ],
        ),
      );
    }

    return _buildDataTable(rows);
  }

  List<Map<String, dynamic>> _extractRows(Map<String, dynamic> data) {
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

  Widget _buildDataTable(List<Map<String, dynamic>> rows) {
    final headers = rows.first.keys.toList();

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // Summary card if the data has a 'resumen' key.
        if (context.read<ReportesController>().currentData.containsKey('resumen'))
          _buildSummaryCard(context.read<ReportesController>().currentData['resumen']),

        SectionCard(
          padding: EdgeInsets.zero,
          child: SingleChildScrollView(
            scrollDirection: Axis.horizontal,
            child: DataTable(
              headingRowColor: WidgetStateProperty.all(AppTheme.primary.withValues(alpha: 0.06)),
              columnSpacing: 20,
              columns: headers
                  .map((h) => DataColumn(
                        label: Text(
                          _formatHeader(h),
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 12),
                        ),
                      ))
                  .toList(),
              rows: rows
                  .map((row) => DataRow(
                        cells: headers
                            .map((h) => DataCell(
                                  Text(
                                    _formatCellValue(row[h]),
                                    style: const TextStyle(fontSize: 12),
                                  ),
                                ))
                            .toList(),
                      ))
                  .toList(),
            ),
          ),
        ),

        const SizedBox(height: 12),
        Text(
          '${rows.length} registro(s)',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.grey),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSummaryCard(dynamic resumen) {
    if (resumen is! Map<String, dynamic>) return const SizedBox.shrink();

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Resumen',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 12),
            Wrap(
              spacing: 16,
              runSpacing: 12,
              children: resumen.entries.map((e) {
                return Container(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
                  decoration: BoxDecoration(
                    gradient: const LinearGradient(
                      colors: [AppTheme.primary, Color(0xFF153259)],
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      Text(
                        _formatCellValue(e.value),
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                          fontSize: 18,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        _formatHeader(e.key),
                        style: const TextStyle(color: Colors.white70, fontSize: 11),
                      ),
                    ],
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  String _formatHeader(String key) {
    return key.replaceAll('_', ' ').replaceFirstMapped(
          RegExp(r'^.'),
          (m) => m.group(0)!.toUpperCase(),
        );
  }

  String _formatCellValue(dynamic value) {
    if (value == null) return '—';
    if (value is double) return value.toStringAsFixed(2);
    return value.toString();
  }

  // ── Actions ──────────────────────────────────────────────────────────

  Future<void> _openVoiceAssistant(ReportesController controller) async {
    final applied = await VoiceAssistantModal.show(context);
    if (applied == true) {
      // Update the filter text fields to reflect what the voice command set.
      final filtros = controller.filtros;
      _fechaInicioCtrl.text = filtros['fecha_inicio']?.toString() ?? '';
      _fechaFinCtrl.text = filtros['fecha_fin']?.toString() ?? '';
    }
  }

  void _handleExport(String type, ReportesController controller) {
    switch (type) {
      case 'excel':
        controller.exportToExcel();
        break;
      case 'pdf':
        controller.exportToPdf();
        break;
      case 'html':
        controller.exportToHtml();
        break;
    }
  }
}
