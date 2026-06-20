import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../models/dashboard_model.dart';
import '../state/dashboard_controller.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<DashboardController>().loadKpis();
    });
  }

  Widget _datePickerTile(
    BuildContext ctx, {
    required String label,
    required DateTime? date,
    required void Function(DateTime) onPick,
  }) {
    return InkWell(
      onTap: () async {
        final now = DateTime.now();
        final picked = await showDatePicker(
          context: ctx,
          initialDate: date ?? now,
          firstDate: DateTime(2020),
          lastDate: now.add(const Duration(days: 1)),
        );
        if (picked != null) onPick(picked);
      },
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Icon(Icons.calendar_today_rounded,
                size: 18, color: Colors.grey.shade500),
            const SizedBox(width: 12),
            Text(
              date != null
                  ? DateFormat('dd/MM/yyyy').format(date)
                  : label,
              style: TextStyle(
                color: date != null ? AppTheme.primary : Colors.grey.shade500,
                fontWeight: date != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<DashboardController>();

    return Scaffold(
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null && controller.data == null
              ? _buildError(controller)
              : controller.data == null
                  ? const Center(child: Text('Sin datos disponibles'))
                  : RefreshIndicator(
                      onRefresh: () => controller.loadKpis(force: true),
                      child: _buildContent(controller.data!),
                    ),
    );
  }

  Widget _buildError(DashboardController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded,
                size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(controller.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: () => controller.loadKpis(force: true),
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildContent(DashboardData data) {
    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Filter chip bar
          _buildActiveFilters(),
          const SizedBox(height: 4),

          // KPI Cards
          _buildKpiGrid(data.kpis),
          const SizedBox(height: 24),

          // Ventas por Turno chart
          if (data.ventasPorTurno.isNotEmpty) ...[
            _sectionTitle('Ventas por turno', Icons.schedule_rounded),
            const SizedBox(height: 12),
            _buildVentasTurnoChart(data.ventasPorTurno),
            const SizedBox(height: 24),
          ],

          // Métodos de pago chart
          if (data.metodosPago.isNotEmpty) ...[
            _sectionTitle('Métodos de pago', Icons.payment_rounded),
            const SizedBox(height: 12),
            _buildMetodosPagoChart(data.metodosPago),
            const SizedBox(height: 24),
          ],

          // Rendimiento surtidores
          if (data.rendimientoSurtidores.isNotEmpty) ...[
            _sectionTitle('Rendimiento surtidores', Icons.local_gas_station_rounded),
            const SizedBox(height: 12),
            _buildRendimientoList(data.rendimientoSurtidores),
            const SizedBox(height: 24),
          ],

          // Estado surtidores
          if (data.estadoSurtidores.isNotEmpty) ...[
            _sectionTitle('Estado de surtidores', Icons.info_rounded),
            const SizedBox(height: 12),
            _buildEstadoSurtidores(data.estadoSurtidores),
          ],

          const SizedBox(height: 20),
        ],
      ),
    );
  }

  Widget _buildActiveFilters() {
    final controller = context.read<DashboardController>();
    if (controller.fechaInicio == null && controller.fechaFin == null) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Wrap(
        spacing: 8,
        children: [
          if (controller.fechaInicio != null)
            Chip(
              label: Text('Desde: ${controller.fechaInicio}',
                  style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: controller.clearFiltros,
              backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
            ),
          if (controller.fechaFin != null)
            Chip(
              label: Text('Hasta: ${controller.fechaFin}',
                  style: const TextStyle(fontSize: 12)),
              deleteIcon: const Icon(Icons.close, size: 16),
              onDeleted: controller.clearFiltros,
              backgroundColor: AppTheme.secondary.withValues(alpha: 0.1),
            ),
        ],
      ),
    );
  }

  // ── KPI Grid ──────────────────────────────────────────────────────────

  Widget _buildKpiGrid(KpisPrincipales kpis) {
    final items = [
      _KpiItem(
        title: 'Ventas Totales',
        value: 'Bs ${_formatNumber(kpis.ventasTotalesBs)}',
        icon: Icons.attach_money_rounded,
        gradient: const [Color(0xFF00C989), Color(0xFF00A070)],
      ),
      _KpiItem(
        title: 'Litros Vendidos',
        value: _formatNumber(kpis.litrosVendidos),
        icon: Icons.water_drop_rounded,
        gradient: const [Color(0xFF1E88E5), Color(0xFF1565C0)],
      ),
      _KpiItem(
        title: 'Margen Ganancia',
        value: 'Bs ${_formatNumber(kpis.margenGananciaBs)}',
        icon: Icons.trending_up_rounded,
        gradient: const [Color(0xFFFF8A00), Color(0xFFE67E00)],
      ),
      _KpiItem(
        title: 'Prom. Litros/Venta',
        value: kpis.promedioLitrosVenta.toStringAsFixed(1),
        icon: Icons.speed_rounded,
        gradient: const [Color(0xFF7C4DFF), Color(0xFF651FFF)],
      ),
    ];

    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 14,
        crossAxisSpacing: 14,
        childAspectRatio: 1.25,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _buildKpiCard(items[index]),
    );
  }

  Widget _buildKpiCard(_KpiItem item) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: item.gradient,
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: item.gradient.first.withValues(alpha: 0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(item.icon, color: Colors.white, size: 20),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                item.value,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.w800,
                ),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 2),
              Text(
                item.title,
                style: TextStyle(
                  color: Colors.white.withValues(alpha: 0.8),
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Ventas por Turno Bar Chart ────────────────────────────────────────

  Widget _buildVentasTurnoChart(List<VentaTurno> turnos) {
    final colors = [
      const Color(0xFFFFB74D),
      const Color(0xFF4FC3F7),
      const Color(0xFF7C4DFF),
    ];

    return SectionCard(
      child: SizedBox(
        height: 220,
        child: BarChart(
          BarChartData(
            alignment: BarChartAlignment.spaceAround,
            maxY: turnos.fold<double>(
                    0, (max, t) => t.totalBs > max ? t.totalBs : max) *
                1.2,
            barTouchData: BarTouchData(
              touchTooltipData: BarTouchTooltipData(
                getTooltipItem: (group, groupIndex, rod, rodIndex) {
                  return BarTooltipItem(
                    '${turnos[group.x].turno}\nBs ${_formatNumber(rod.toY)}',
                    const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.w700,
                      fontSize: 12,
                    ),
                  );
                },
              ),
            ),
            titlesData: FlTitlesData(
              show: true,
              bottomTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  getTitlesWidget: (value, meta) {
                    final index = value.toInt();
                    if (index < 0 || index >= turnos.length) {
                      return const SizedBox.shrink();
                    }
                    return Padding(
                      padding: const EdgeInsets.only(top: 8),
                      child: Text(
                        turnos[index].turno,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppTheme.primary,
                        ),
                      ),
                    );
                  },
                  reservedSize: 30,
                ),
              ),
              leftTitles: AxisTitles(
                sideTitles: SideTitles(
                  showTitles: true,
                  reservedSize: 55,
                  getTitlesWidget: (value, meta) {
                    return Text(
                      _formatCompact(value),
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.grey.shade500,
                      ),
                    );
                  },
                ),
              ),
              topTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
              rightTitles: const AxisTitles(
                  sideTitles: SideTitles(showTitles: false)),
            ),
            gridData: FlGridData(
              show: true,
              drawVerticalLine: false,
              horizontalInterval: _calcInterval(turnos.fold<double>(
                  0, (max, t) => t.totalBs > max ? t.totalBs : max)),
              getDrawingHorizontalLine: (value) => FlLine(
                color: Colors.grey.shade200,
                strokeWidth: 1,
              ),
            ),
            borderData: FlBorderData(show: false),
            barGroups: List.generate(
              turnos.length,
              (i) => BarChartGroupData(
                x: i,
                barRods: [
                  BarChartRodData(
                    toY: turnos[i].totalBs,
                    width: 28,
                    color: colors[i % colors.length],
                    borderRadius: const BorderRadius.vertical(
                        top: Radius.circular(8)),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ── Métodos de Pago Pie Chart ─────────────────────────────────────────

  Widget _buildMetodosPagoChart(List<MetodoPago> metodos) {
    final colors = [
      const Color(0xFF00C989),
      const Color(0xFF1E88E5),
      const Color(0xFFFF8A00),
      const Color(0xFF7C4DFF),
      const Color(0xFFE53935),
    ];

    final total = metodos.fold<double>(0, (sum, m) => sum + m.totalBs);

    return SectionCard(
      child: Column(
        children: [
          SizedBox(
            height: 200,
            child: PieChart(
              PieChartData(
                centerSpaceRadius: 40,
                sectionsSpace: 3,
                sections: List.generate(
                  metodos.length,
                  (i) {
                    final pct = total > 0 ? (metodos[i].totalBs / total * 100) : 0;
                    return PieChartSectionData(
                      color: colors[i % colors.length],
                      value: metodos[i].totalBs,
                      title: '${pct.toStringAsFixed(0)}%',
                      radius: 50,
                      titleStyle: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          // Legend
          ...List.generate(
            metodos.length,
            (i) => Padding(
              padding: const EdgeInsets.symmetric(vertical: 4),
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: colors[i % colors.length],
                      borderRadius: BorderRadius.circular(3),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      metodos[i].metodo,
                      style: const TextStyle(
                          fontSize: 13, fontWeight: FontWeight.w600),
                    ),
                  ),
                  Text(
                    'Bs ${_formatNumber(metodos[i].totalBs)}',
                    style: const TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.primary,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Text(
                    '${metodos[i].porcentaje}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.grey.shade500,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Rendimiento surtidores ────────────────────────────────────────────

  Widget _buildRendimientoList(List<RendimientoSurtidor> surtidores) {
    return SectionCard(
      padding: const EdgeInsets.all(0),
      child: Column(
        children: List.generate(
          surtidores.length,
          (i) {
            final s = surtidores[i];
            final isLast = i == surtidores.length - 1;
            return Container(
              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
              decoration: BoxDecoration(
                border: isLast
                    ? null
                    : Border(
                        bottom: BorderSide(color: Colors.grey.shade100)),
              ),
              child: Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: AppTheme.primary.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.local_gas_station_rounded,
                      color: AppTheme.primary,
                      size: 20,
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          s.surtidor,
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 14,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${_formatNumber(s.litros)} litros',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade500,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  // ── Estado surtidores ─────────────────────────────────────────────────

  Widget _buildEstadoSurtidores(Map<String, int> estados) {
    return Row(
      children: estados.entries.map((e) {
        Color color;
        IconData icon;
        switch (e.key.toLowerCase()) {
          case 'activo':
            color = const Color(0xFF2E7D32);
            icon = Icons.check_circle_rounded;
            break;
          case 'en mantenimiento':
            color = const Color(0xFFE65100);
            icon = Icons.build_circle_rounded;
            break;
          case 'inactivo':
            color = const Color(0xFFC62828);
            icon = Icons.cancel_rounded;
            break;
          default:
            color = Colors.grey;
            icon = Icons.help_rounded;
        }

        return Expanded(
          child: Container(
            margin: const EdgeInsets.symmetric(horizontal: 4),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: color.withValues(alpha: 0.2)),
            ),
            child: Column(
              children: [
                Icon(icon, color: color, size: 28),
                const SizedBox(height: 8),
                Text(
                  '${e.value}',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w800,
                    color: color,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  e.key,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 11,
                    color: color,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────

  Widget _sectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(icon, size: 20, color: AppTheme.primary),
        const SizedBox(width: 8),
        Text(
          title,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w800,
                color: AppTheme.primary,
              ),
        ),
      ],
    );
  }

  String _formatNumber(double value) {
    if (value >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(1)}M';
    }
    if (value >= 1000) {
      return NumberFormat('#,##0.00', 'es_BO').format(value);
    }
    return value.toStringAsFixed(2);
  }

  String _formatCompact(double value) {
    if (value >= 1000000) return '${(value / 1000000).toStringAsFixed(1)}M';
    if (value >= 1000) return '${(value / 1000).toStringAsFixed(0)}K';
    return value.toStringAsFixed(0);
  }

  double _calcInterval(double maxValue) {
    if (maxValue <= 0) return 1;
    if (maxValue <= 100) return 25;
    if (maxValue <= 1000) return 250;
    if (maxValue <= 10000) return 2500;
    if (maxValue <= 100000) return 25000;
    return (maxValue / 4).roundToDouble();
  }
}

class _KpiItem {
  const _KpiItem({
    required this.title,
    required this.value,
    required this.icon,
    required this.gradient,
  });

  final String title;
  final String value;
  final IconData icon;
  final List<Color> gradient;
}
