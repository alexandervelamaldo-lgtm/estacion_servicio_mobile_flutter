import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/config/app_config.dart';
import '../../../core/router/app_router.dart';
import '../../../shared/widgets/brand_header.dart';
import '../state/auth_controller.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _redirect();
    });
  }

  Future<void> _redirect() async {
  final authController = context.read<AuthController>();
  while (authController.loading) {
    await Future<void>.delayed(const Duration(milliseconds: 120));
  }

  if (!mounted) return;

  if (!authController.isAuthenticated) {
    Navigator.pushReplacementNamed(context, AppRoutes.login);
    return;
  }

  final user = authController.user;
  final isSuperuser = user?.isSuperuser ?? false;

  if (isSuperuser) {
    await authController.logout();
    Navigator.pushReplacementNamed(context, AppRoutes.login);
    return;
  }

  Navigator.pushReplacementNamed(context, AppRoutes.mainLayout);
}

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      body: Container(
        width: double.infinity,
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: [
              theme.colorScheme.primary,
              const Color(0xFF112749),
            ],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const BrandHeader(
              subtitle: 'Plataforma móvil para compras y seguimiento',
            ),
            const SizedBox(height: 24),
            CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(theme.colorScheme.secondary),
            ),
            const SizedBox(height: 18),
            Text(
              'Entorno ${AppConfig.environmentName}',
              style: theme.textTheme.bodyMedium?.copyWith(color: Colors.white70),
            ),
          ],
        ),
      ),
    );
  }
}
