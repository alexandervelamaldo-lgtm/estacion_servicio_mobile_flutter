import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../models/prepago_orden.dart';
import '../state/prepago_controller.dart';

class PrepagoHistoryScreen extends StatefulWidget {
  const PrepagoHistoryScreen({super.key});

  @override
  State<PrepagoHistoryScreen> createState() => _PrepagoHistoryScreenState();
}

class _PrepagoHistoryScreenState extends State<PrepagoHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrepagoController>().loadOrdenes();
    });
  }

  Future<void> _refresh() async {
    await context.read<PrepagoController>().loadOrdenes();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PrepagoController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis Compras Prepago'),
        actions: [
          IconButton(
            onPressed: controller.loadingHistory ? null : _refresh,
            tooltip: 'Actualizar',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: controller.loadingHistory && controller.ordenes.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : controller.ordenes.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
                    padding: const EdgeInsets.all(20),
                    itemCount: controller.ordenes.length +
                        (controller.errorMessage != null ? 1 : 0),
                    itemBuilder: (context, index) {
                      if (controller.errorMessage != null && index == 0) {
                        return _buildErrorCard(controller.errorMessage!);
                      }
                      final adjustedIndex =
                          controller.errorMessage != null ? index - 1 : index;
                      return _buildOrderCard(
                        controller.ordenes[adjustedIndex],
                        controller,
                      );
                    },
                  ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return ListView(
      children: [
        const SizedBox(height: 100),
        Center(
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(24),
                decoration: BoxDecoration(
                  color: AppTheme.secondary.withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.receipt_long_rounded,
                  size: 56,
                  color: AppTheme.secondary.withValues(alpha: 0.5),
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'Sin compras prepago todavía',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                      color: Colors.grey.shade600,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Tus órdenes prepago aparecerán aquí',
                style: TextStyle(color: Colors.grey.shade400),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildErrorCard(String message) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: SectionCard(
        child: Row(
          children: [
            Icon(Icons.warning_amber_rounded, color: Colors.orange.shade600),
            const SizedBox(width: 12),
            Expanded(child: Text(message)),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(PrepagoOrden orden, PrepagoController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(20),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.04),
              blurRadius: 12,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Encabezado: Número orden + Estado chip
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          orden.numeroOrden,
                          style: Theme.of(context)
                              .textTheme
                              .titleSmall
                              ?.copyWith(
                                fontWeight: FontWeight.w800,
                                color: AppTheme.primary,
                                letterSpacing: 0.5,
                              ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          _dateFormat.format(orden.fechaCreacion),
                          style: TextStyle(
                            color: Colors.grey.shade500,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                  _buildEstadoChip(orden.estado),
                ],
              ),
              const SizedBox(height: 14),

              // Detalles
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: Colors.grey.shade50,
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Column(
                  children: [
                    _detailRow(
                      Icons.local_gas_station_rounded,
                      'Combustible',
                      orden.tipoCombustibleNombre,
                    ),
                    const SizedBox(height: 8),
                    _detailRow(
                      Icons.water_drop_rounded,
                      'Litros',
                      '${orden.litrosEstimados.toStringAsFixed(2)} L',
                    ),
                    const SizedBox(height: 8),
                    _detailRow(
                      Icons.payments_rounded,
                      'Monto',
                      'Bs ${orden.montoTotal.toStringAsFixed(2)}',
                      bold: true,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Botón PDF
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: controller.isLoading
                      ? null
                      : () async {
                          await controller.descargarYCompartirPdf(orden.id);
                        },
                  icon: controller.isLoading
                      ? const SizedBox(
                          width: 16,
                          height: 16,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.picture_as_pdf_rounded, size: 18),
                  label: Text(controller.isLoading
                      ? 'Descargando...'
                      : 'Ver Comprobante PDF'),
                  style: OutlinedButton.styleFrom(
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 12),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _detailRow(IconData icon, String label, String value,
      {bool bold = false}) {
    return Row(
      children: [
        Icon(icon, size: 18, color: Colors.grey.shade500),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(color: Colors.grey.shade600, fontSize: 13),
        ),
        const Spacer(),
        Text(
          value,
          style: TextStyle(
            fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
            color: AppTheme.primary,
            fontSize: bold ? 15 : 13,
          ),
        ),
      ],
    );
  }

  Widget _buildEstadoChip(String estado) {
    Color backgroundColor;
    Color textColor;

    switch (estado.toUpperCase()) {
      case 'PAGADO':
        backgroundColor = const Color(0xFFE8F5E9);
        textColor = const Color(0xFF2E7D32);
        break;
      case 'DESPACHADO':
        backgroundColor = const Color(0xFFE3F2FD);
        textColor = const Color(0xFF1565C0);
        break;
      case 'EXPIRADO':
        backgroundColor = const Color(0xFFFFEBEE);
        textColor = const Color(0xFFC62828);
        break;
      default:
        backgroundColor = Colors.grey.shade100;
        textColor = Colors.grey.shade700;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: backgroundColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        PrepagoOrden.estadoLabel(estado),
        style: TextStyle(
          color: textColor,
          fontWeight: FontWeight.w700,
          fontSize: 12,
        ),
      ),
    );
  }
}
