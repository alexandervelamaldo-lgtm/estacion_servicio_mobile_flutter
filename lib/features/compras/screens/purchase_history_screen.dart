import 'dart:async';

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../auth/state/auth_controller.dart';
import '../../../shared/widgets/section_card.dart';
import '../state/purchase_controller.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen>
    with WidgetsBindingObserver {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');
  Timer? _historyRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _refreshHistory();
    });
    _historyRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) {
        return;
      }
      _refreshHistory();
    });
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && mounted) {
      _refreshHistory();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _historyRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _refreshHistory() async {
    final controller = context.read<PurchaseController>();
    if (controller.loadingHistory) {
      return;
    }
    await controller.loadPurchases();
  }

  String _buildSyncLabel(DateTime? syncedAt) {
    if (syncedAt == null) {
      return 'Todavia no se sincronizo el historial.';
    }
    return 'Ultima sincronizacion: ${_dateFormat.format(syncedAt)}';
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchaseController>();
    final authController = context.watch<AuthController>();
    final currentUser = authController.user;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de compras'),
        actions: [
          IconButton(
            onPressed: controller.loadingHistory ? null : _refreshHistory,
            tooltip: 'Actualizar historial',
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _refreshHistory,
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    currentUser == null
                        ? 'Sesion no identificada.'
                        : 'Cuenta activa: ${currentUser.nombre} (${currentUser.email})',
                    style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(_buildSyncLabel(controller.lastHistorySyncAt)),
                  const SizedBox(height: 6),
                  Text('Registros cargados: ${controller.purchases.length}'),
                  if (controller.loadingHistory) ...[
                    const SizedBox(height: 12),
                    const LinearProgressIndicator(),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 12),
            if (controller.errorMessage != null)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: SectionCard(
                  child: Text(controller.errorMessage!),
                ),
              ),
            if (controller.loadingHistory && controller.purchases.isEmpty)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.purchases.isEmpty)
              SectionCard(
                child: Text('Todavia no tienes compras registradas.'),
              )
            else
              ...controller.purchases.map(
                (purchase) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                purchase.combustibleNombre.isEmpty
                                    ? purchase.tipoCombustible
                                    : purchase.combustibleNombre,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w800),
                              ),
                            ),
                            Text(
                              'Bs ${purchase.total.toStringAsFixed(2)}',
                              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w800,
                                  ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          '${purchase.cantidad.toStringAsFixed(2)} ${purchase.unidad} · '
                          'Bs ${purchase.precioUnitario.toStringAsFixed(2)} por unidad',
                        ),
                        const SizedBox(height: 8),
                        Text(_dateFormat.format(purchase.fechaHora)),
                        if (purchase.observacion.isNotEmpty) ...[
                          const SizedBox(height: 10),
                          Text(purchase.observacion),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
