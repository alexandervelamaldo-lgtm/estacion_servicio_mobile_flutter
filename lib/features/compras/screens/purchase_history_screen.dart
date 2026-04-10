import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/section_card.dart';
import '../state/purchase_controller.dart';

class PurchaseHistoryScreen extends StatefulWidget {
  const PurchaseHistoryScreen({super.key});

  @override
  State<PurchaseHistoryScreen> createState() => _PurchaseHistoryScreenState();
}

class _PurchaseHistoryScreenState extends State<PurchaseHistoryScreen> {
  final DateFormat _dateFormat = DateFormat('dd/MM/yyyy HH:mm');

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseController>().loadPurchases();
    });
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchaseController>();

    return Scaffold(
      appBar: AppBar(title: const Text('Historial de compras')),
      body: RefreshIndicator(
        onRefresh: () => context.read<PurchaseController>().loadPurchases(),
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            if (controller.loadingHistory)
              const Center(
                child: Padding(
                  padding: EdgeInsets.all(32),
                  child: CircularProgressIndicator(),
                ),
              )
            else if (controller.purchases.isEmpty)
              SectionCard(
                child: Text(
                  controller.errorMessage ?? 'Todavía no tienes compras registradas.',
                ),
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
