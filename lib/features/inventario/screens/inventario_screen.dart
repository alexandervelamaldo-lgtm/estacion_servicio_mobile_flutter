import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../models/tanque.dart';
import '../state/inventario_controller.dart';

class InventarioScreen extends StatefulWidget {
  const InventarioScreen({super.key});

  @override
  State<InventarioScreen> createState() => _InventarioScreenState();
}

class _InventarioScreenState extends State<InventarioScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<InventarioController>().cargar();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<InventarioController>();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Control de Combustible'),
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
              : controller.tanques.isEmpty
                  ? const Center(child: Text('No hay tanques registrados.'))
                  : RefreshIndicator(
                      onRefresh: controller.cargar,
                      child: ListView.builder(
                        padding: const EdgeInsets.all(16),
                        itemCount: controller.tanques.length,
                        itemBuilder: (context, index) =>
                            _buildTanque(controller.tanques[index], controller),
                      ),
                    ),
    );
  }

  Widget _buildError(InventarioController controller) {
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

  Widget _buildTanque(Tanque tanque, InventarioController controller) {
    final color = tanque.enAlerta
        ? Colors.red
        : tanque.porcentaje < 50
            ? Colors.orange
            : Colors.green;

    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: SectionCard(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Icon(Icons.water_drop_rounded, color: color, size: 22),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        tanque.tipoCombustible,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w800,
                            ),
                      ),
                      Text(
                        tanque.sucursalNombre,
                        style: Theme.of(context)
                            .textTheme
                            .bodySmall
                            ?.copyWith(color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                if (tanque.enAlerta)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.warning_rounded, size: 14, color: Colors.red),
                        SizedBox(width: 4),
                        Text('ALERTA',
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.red,
                                fontWeight: FontWeight.w700)),
                      ],
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 16),

            // Barra de nivel
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text('Nivel actual',
                    style: Theme.of(context).textTheme.bodySmall),
                Text(
                  '${tanque.nivelActual.toStringAsFixed(0)} / ${tanque.capacidadMaxima.toStringAsFixed(0)} Lt',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(fontWeight: FontWeight.w700),
                ),
              ],
            ),
            const SizedBox(height: 6),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: tanque.porcentaje / 100,
                minHeight: 12,
                backgroundColor: Colors.grey.shade200,
                valueColor: AlwaysStoppedAnimation<Color>(color),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              '${tanque.porcentaje.toStringAsFixed(1)}%',
              style: TextStyle(
                  fontSize: 12, color: color, fontWeight: FontWeight.w700),
            ),
            const SizedBox(height: 16),

            // Botones
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.procesando
                        ? null
                        : () => _mostrarDescarga(tanque, controller),
                    icon: const Icon(Icons.add_rounded, size: 18),
                    label: const Text('Registrar descarga'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: controller.procesando
                        ? null
                        : () => _mostrarAmpliarCapacidad(tanque, controller),
                    icon: const Icon(Icons.expand_rounded, size: 18),
                    label: const Text('Ampliar capacidad'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarDescarga(
      Tanque tanque, InventarioController controller) async {
    final volumenCtrl = TextEditingController();
    final obsCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Registrar descarga — ${tanque.tipoCombustible}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Disponible: ${(tanque.capacidadMaxima - tanque.nivelActual).toStringAsFixed(0)} Lt',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: volumenCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Volumen a cargar (Lt)',
                prefixIcon: Icon(Icons.water_drop_rounded),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: obsCtrl,
              decoration: const InputDecoration(
                labelText: 'Observaciones (opcional)',
                prefixIcon: Icon(Icons.notes_rounded),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final volumen = double.tryParse(volumenCtrl.text);
                if (volumen == null || volumen <= 0) return;
                Navigator.pop(context);
                final ok = await controller.registrarDescarga(
                  tanqueId: tanque.id,
                  volumen: volumen,
                  observaciones: obsCtrl.text,
                );
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(controller.successMessage ?? 'Descarga registrada.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.secondary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar descarga'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _mostrarAmpliarCapacidad(
      Tanque tanque, InventarioController controller) async {
    final capacidadCtrl = TextEditingController();

    await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => Padding(
        padding: EdgeInsets.fromLTRB(
            20, 20, 20, MediaQuery.of(context).viewInsets.bottom + 20),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Ampliar capacidad — ${tanque.tipoCombustible}',
              style: Theme.of(context)
                  .textTheme
                  .titleMedium
                  ?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 6),
            Text(
              'Capacidad actual: ${tanque.capacidadMaxima.toStringAsFixed(0)} Lt',
              style: const TextStyle(color: Colors.grey, fontSize: 13),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: capacidadCtrl,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Nueva capacidad (Lt)',
                prefixIcon: Icon(Icons.expand_rounded),
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () async {
                final capacidad = double.tryParse(capacidadCtrl.text);
                if (capacidad == null || capacidad <= 0) return;
                Navigator.pop(context);
                final ok = await controller.ampliarCapacidad(
                  tanqueId: tanque.id,
                  nuevaCapacidad: capacidad,
                );
                if (ok && mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text(controller.successMessage ?? 'Capacidad ampliada.'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: AppTheme.primary,
                foregroundColor: Colors.white,
              ),
              child: const Text('Confirmar'),
            ),
          ],
        ),
      ),
    );
  }
}