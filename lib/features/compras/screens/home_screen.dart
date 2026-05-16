import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../shared/widgets/section_card.dart';
import '../../auth/state/auth_controller.dart';
import '../state/purchase_controller.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  Timer? _catalogRefreshTimer;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PurchaseController>().loadCatalog();
    });
    _catalogRefreshTimer = Timer.periodic(const Duration(seconds: 15), (_) {
      if (!mounted) {
        return;
      }
      final controller = context.read<PurchaseController>();
      if (!controller.loadingCatalog) {
        controller.loadCatalog(force: true);
      }
    });
  }

  @override
  void dispose() {
    _catalogRefreshTimer?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final purchaseController = context.watch<PurchaseController>();
    final user = authController.user;
    final catalog = purchaseController.catalog;

    return Scaffold(
      appBar: AppBar(
        title: const Text('SurtidorBolivia'),
        actions: [
          IconButton(
            onPressed: authController.submitting
                ? null
                : () async {
                    await context.read<AuthController>().logout();
                    if (!context.mounted) {
                      return;
                    }
                    Navigator.pushNamedAndRemoveUntil(context, AppRoutes.login, (_) => false);
                  },
            icon: const Icon(Icons.logout_rounded),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          final controller = context.read<PurchaseController>();
          await controller.loadCatalog(force: true);
          await controller.loadPurchases();
        },
        child: ListView(
          padding: const EdgeInsets.all(20),
          children: [
            Container(
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [AppTheme.primary, Color(0xFF153259)],
                ),
                borderRadius: BorderRadius.circular(24),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Bienvenido, ${user?.nombre ?? 'Usuario'}',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                          color: Colors.white,
                          fontWeight: FontWeight.w800,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    user?.email ?? '',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: Colors.white70),
                  ),
                  const SizedBox(height: 18),
                  Text(
                    'API ${AppConfig.baseUrl}',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(color: Colors.white54),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            SectionCard(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Acciones rápidas',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 16),
                  ElevatedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.purchase),
                    icon: const Icon(Icons.add_shopping_cart_rounded),
                    label: const Text('Registrar compra'),
                  ),
                  const SizedBox(height: 12),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, AppRoutes.history),
                    icon: const Icon(Icons.receipt_long_rounded),
                    label: const Text('Ver historial'),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Combustibles disponibles',
              style: Theme.of(context).textTheme.titleLarge?.copyWith(fontWeight: FontWeight.w800),
            ),
            const SizedBox(height: 12),
            if (purchaseController.loadingCatalog)
              const Center(child: Padding(
                padding: EdgeInsets.all(24),
                child: CircularProgressIndicator(),
              ))
            else if (catalog.isEmpty)
              SectionCard(
                child: Text(
                  purchaseController.errorMessage ?? 'No se pudo cargar el catálogo.',
                ),
              )
            else
              ...catalog.map(
                (item) => Padding(
                  padding: const EdgeInsets.only(bottom: 12),
                  child: SectionCard(
                    child: Row(
                      children: [
                        Container(
                          width: 48,
                          height: 48,
                          decoration: BoxDecoration(
                            color: AppTheme.secondary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(16),
                          ),
                          child: const Icon(Icons.local_gas_station_rounded, color: AppTheme.secondary),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                item.nombre,
                                style: Theme.of(context)
                                    .textTheme
                                    .titleMedium
                                    ?.copyWith(fontWeight: FontWeight.w700),
                              ),
                              const SizedBox(height: 4),
                              Text('${item.unidad} · Bs ${item.precioUnitario.toStringAsFixed(2)}'),
                            ],
                          ),
                        ),
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
