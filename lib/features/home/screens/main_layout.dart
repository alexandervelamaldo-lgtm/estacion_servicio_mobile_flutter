import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/router/app_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/state/auth_controller.dart';
import '../../compras/screens/home_screen.dart';
import '../../dashboard/screens/dashboard_screen.dart';
import '../../dashboard/state/dashboard_controller.dart';
import '../../inventario/screens/inventario_screen.dart';
import '../../monitoreo/screens/monitoreo_screen.dart';
import '../../perfil/screens/profile_screen.dart';
import '../../prepago/screens/prepago_history_screen.dart';
import '../../reportes/screens/reportes_screen.dart';

/// Layout principal con BottomNavigationBar.
/// Las pestañas mostradas dependen del rol del usuario:
/// - Cliente: Home, Mis Compras, Mi Perfil
/// - Admin/Gerente: Dashboard, Reportes, Monitoreo, Control de Combustible
class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _currentIndex = 0;

  bool _isAdmin(AuthController authController) {
    final user = authController.user;
    if (user == null) return false;
    final rol = user.rol?.toLowerCase() ?? '';
    return user.isSuperuser == true || user.isStaff == true || rol == 'administrador' || rol == 'gerente';
  }

  List<_TabConfig> _buildTabs(bool isAdmin) {
    if (isAdmin) {
      return [
        _TabConfig(
          screen: const DashboardScreen(),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.dashboard_rounded),
            label: 'Dashboard',
          ),
          title: 'Dashboard',
          hasOwnAppBar: false,
        ),
        _TabConfig(
          screen: const ReportesScreen(),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.insights_rounded),
            label: 'Reportes',
          ),
          title: 'Reportes',
          hasOwnAppBar: true,
        ),
        _TabConfig(
          screen: const MonitoreoScreen(),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.monitor_heart_rounded),
            label: 'Monitoreo',
          ),
          title: 'Monitoreo',
          hasOwnAppBar: true,
        ),
        _TabConfig(
          screen: const InventarioScreen(),
          item: const BottomNavigationBarItem(
            icon: Icon(Icons.water_drop_rounded),
            label: 'Control',
          ),
          title: 'Control',
          hasOwnAppBar: true,
        ),
      ];
    }

    return [
      _TabConfig(
        screen: const HomeScreen(),
        item: const BottomNavigationBarItem(
          icon: Icon(Icons.home_rounded),
          label: 'Home',
        ),
        title: 'SurtidorBolivia',
        hasOwnAppBar: true,
      ),
      _TabConfig(
        screen: const PrepagoHistoryScreen(),
        item: const BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long_rounded),
          label: 'Mis compras',
        ),
        title: 'Mis Compras Prepago',
        hasOwnAppBar: true,
      ),
      _TabConfig(
        screen: const ProfileScreen(),
        item: const BottomNavigationBarItem(
          icon: Icon(Icons.person_rounded),
          label: 'Mi perfil',
        ),
        title: 'Mi Perfil',
        hasOwnAppBar: false,
      ),
    ];
  }

  List<Widget>? _buildActions(
      bool isAdmin, AuthController authController) {
    final actions = <Widget>[];

    // Filter button for Dashboard tab (admin index 0)
    if (isAdmin && _currentIndex == 0) {
      actions.add(
        IconButton(
          onPressed: _showDateFilterBottomSheet,
          icon: const Icon(Icons.filter_list_rounded),
          tooltip: 'Filtrar por fecha',
        ),
      );
    }

    // Logout button
    actions.add(
      IconButton(
        onPressed: authController.submitting
            ? null
            : () async {
                await context.read<AuthController>().logout();
                if (!context.mounted) return;
                Navigator.pushNamedAndRemoveUntil(
                    context, AppRoutes.login, (_) => false);
              },
        icon: const Icon(Icons.logout_rounded),
      ),
    );

    return actions;
  }

  void _showDateFilterBottomSheet() {
    final controller = context.read<DashboardController>();
    DateTime? inicio;
    DateTime? fin;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setModalState) => Padding(
          padding: EdgeInsets.fromLTRB(
              24, 24, 24, MediaQuery.of(ctx).viewInsets.bottom + 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Filtrar por fecha',
                style: Theme.of(ctx)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w800),
              ),
              const SizedBox(height: 20),
              _datePickerTile(ctx,
                  label: 'Fecha inicio',
                  date: inicio,
                  onPick: (d) => setModalState(() => inicio = d)),
              const SizedBox(height: 12),
              _datePickerTile(ctx,
                  label: 'Fecha fin',
                  date: fin,
                  onPick: (d) => setModalState(() => fin = d)),
              const SizedBox(height: 20),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.clearFiltros();
                      },
                      child: const Text('Limpiar'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        Navigator.pop(ctx);
                        controller.setFechas(
                          fechaInicio: inicio != null
                              ? _formatDate(inicio!)
                              : null,
                          fechaFin: fin != null ? _formatDate(fin!) : null,
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppTheme.secondary,
                        foregroundColor: Colors.white,
                      ),
                      child: const Text('Aplicar'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
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
                  ? '${date.day.toString().padLeft(2, '0')}/${date.month.toString().padLeft(2, '0')}/${date.year}'
                  : label,
              style: TextStyle(
                color:
                    date != null ? AppTheme.primary : Colors.grey.shade500,
                fontWeight:
                    date != null ? FontWeight.w600 : FontWeight.w400,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _formatDate(DateTime d) {
    return '${d.year}-${d.month.toString().padLeft(2, '0')}-${d.day.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    final authController = context.watch<AuthController>();
    final isAdmin = _isAdmin(authController);
    final tabs = _buildTabs(isAdmin);

    // Clamp index in case role changes
    if (_currentIndex >= tabs.length) {
      _currentIndex = 0;
    }

    final currentTab = tabs[_currentIndex];

    return Scaffold(
      appBar: currentTab.hasOwnAppBar
          ? null
          : AppBar(
              title: Text(currentTab.title),
              automaticallyImplyLeading: false,
              actions: _buildActions(isAdmin, authController),
            ),
      body: IndexedStack(
        index: _currentIndex,
        children: tabs.map((t) => t.screen).toList(),
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.08),
              blurRadius: 16,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _currentIndex,
          onTap: (index) => setState(() => _currentIndex = index),
          type: BottomNavigationBarType.fixed,
          backgroundColor: Colors.white,
          selectedItemColor: AppTheme.secondary,
          unselectedItemColor: Colors.grey.shade400,
          selectedFontSize: 12,
          unselectedFontSize: 11,
          selectedLabelStyle: const TextStyle(fontWeight: FontWeight.w700),
          items: tabs.map((t) => t.item).toList(),
        ),
      ),
    );
  }
}

class _TabConfig {
  const _TabConfig({
    required this.screen,
    required this.item,
    required this.title,
    required this.hasOwnAppBar,
  });

  final Widget screen;
  final BottomNavigationBarItem item;
  final String title;
  final bool hasOwnAppBar;
}
