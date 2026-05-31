import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/state/auth_controller.dart';
import '../models/sucursal_monitoreo.dart';
import '../state/monitoreo_controller.dart';

class MonitoreoScreen extends StatefulWidget {
  const MonitoreoScreen({super.key});

  @override
  State<MonitoreoScreen> createState() => _MonitoreoScreenState();
}

class _MonitoreoScreenState extends State<MonitoreoScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<MonitoreoController>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<MonitoreoController>();
    final user = context.watch<AuthController>().user;
    final esGerente = user?.rol == 'gerente';

    return Scaffold(
      appBar: AppBar(
        title: Text(esGerente ? 'Mi Sucursal' : 'Monitoreo de Sucursales'),
        actions: [
          IconButton(
            onPressed: controller.loading ? null : controller.cargar,
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: controller.loading
          ? const Center(child: CircularProgressIndicator())
          : controller.errorMessage != null
              ? _buildError(controller)
              : controller.sucursales.isEmpty
                  ? const Center(child: Text('No hay sucursales disponibles.'))
                  : RefreshIndicator(
                      onRefresh: controller.cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.sucursales.length,
                        itemBuilder: (context, index) =>
                            _buildSucursal(controller.sucursales[index], controller),
                      ),
                    ),
    );
  }

  Widget _buildError(MonitoreoController controller) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.error_outline_rounded, size: 48, color: Colors.red.shade300),
            const SizedBox(height: 12),
            Text(controller.errorMessage!, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            ElevatedButton.icon(
              onPressed: controller.cargar,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Reintentar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSucursal(SucursalMonitoreo sucursal, MonitoreoController controller) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.location_on_rounded, color: AppTheme.primary, size: 20),
                const SizedBox(width: 8),
                Text(
                  sucursal.sucursalNombre,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                      ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            ...sucursal.islas.map((isla) => _buildIsla(isla, controller)),
          ],
        ),
      ),
    );
  }

  Widget _buildIsla(IslaMonitoreo isla, MonitoreoController controller) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header isla
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.08),
              borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            ),
            child: Row(
              children: [
                const Icon(Icons.local_gas_station_rounded,
                    size: 18, color: AppTheme.primary),
                const SizedBox(width: 8),
                Text(
                  'Isla ${isla.numero}',
                  style: const TextStyle(
                      fontWeight: FontWeight.w700, color: AppTheme.primary),
                ),
                const Spacer(),
                if (isla.turnoActivo != null)
                  _chip(
                    Icons.person_rounded,
                    isla.turnoActivo!['operador'].toString(),
                    Colors.green,
                  )
                else
                  _chip(Icons.person_off_rounded, 'Sin turno', Colors.grey),
              ],
            ),
          ),

          // Lados
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: isla.lados
                  .map((lado) => _buildLado(lado, controller))
                  .toList(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildLado(LadoMonitoreo lado, MonitoreoController controller) {
    final color = _estadoColor(lado.estado);

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Row(
        children: [
          Icon(_estadoIcon(lado.estado), color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Lado ${lado.lado}',
                  style: const TextStyle(fontWeight: FontWeight.w600),
                ),
                if (lado.descripcionFalla != null)
                  Text(
                    lado.descripcionFalla!,
                    style: TextStyle(fontSize: 12, color: Colors.red.shade400),
                  ),
              ],
            ),
          ),
          _chip(null, lado.estado, color),
          const SizedBox(width: 8),
          IconButton(
            onPressed: controller.cambiando
                ? null
                : () => _mostrarCambioEstado(lado, controller),
            icon: const Icon(Icons.edit_rounded, size: 18),
            color: AppTheme.primary,
            tooltip: 'Cambiar estado',
          ),
        ],
      ),
    );
  }

  Widget _chip(IconData? icon, String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 12, color: color),
            const SizedBox(width: 4),
          ],
          Text(
            label,
            style: TextStyle(
                fontSize: 11, color: color, fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  Color _estadoColor(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return Colors.green;
      case 'INACTIVO':
        return Colors.orange;
      case 'FALLA':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _estadoIcon(String estado) {
    switch (estado) {
      case 'ACTIVO':
        return Icons.check_circle_rounded;
      case 'INACTIVO':
        return Icons.pause_circle_rounded;
      case 'FALLA':
        return Icons.error_rounded;
      default:
        return Icons.help_rounded;
    }
  }

  Future<void> _mostrarCambioEstado(
      LadoMonitoreo lado, MonitoreoController controller) async {
    String estadoSeleccionado = lado.estado;
    final descripcionCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => StatefulBuilder(
        builder: (context, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Cambiar estado — Lado ${lado.lado}',
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 16),
              ...['ACTIVO', 'INACTIVO', 'FALLA'].map((e) => RadioListTile<String>(
                    value: e,
                    groupValue: estadoSeleccionado,
                    title: Text(e),
                    activeColor: _estadoColor(e),
                    onChanged: (v) => setModalState(() => estadoSeleccionado = v!),
                  )),
              if (estadoSeleccionado == 'FALLA') ...[
                const SizedBox(height: 8),
                TextField(
                  controller: descripcionCtrl,
                  decoration: const InputDecoration(
                    labelText: 'Descripción de la falla',
                    prefixIcon: Icon(Icons.report_problem_rounded),
                  ),
                  maxLines: 2,
                ),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () async {
                  Navigator.pop(context);
                  await controller.cambiarEstado(
                    ladoId: lado.id,
                    estado: estadoSeleccionado,
                    descripcion: descripcionCtrl.text,
                  );
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.secondary,
                  foregroundColor: Colors.white,
                ),
                child: const Text('Confirmar cambio'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}