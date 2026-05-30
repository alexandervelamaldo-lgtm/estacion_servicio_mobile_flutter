import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'core/config/app_config.dart';
import 'core/network/api_client.dart';
import 'core/router/app_router.dart';
import 'core/storage/session_storage.dart';
import 'core/theme/app_theme.dart';
import 'features/auth/services/auth_service.dart';
import 'features/auth/state/auth_controller.dart';
import 'features/compras/services/purchase_service.dart';
import 'features/compras/state/purchase_controller.dart';
import 'features/reportes/services/reportes_service.dart';
import 'features/reportes/services/voice_service.dart';
import 'features/reportes/state/reportes_controller.dart';

void main() {
  final sessionStorage = SessionStorage();
  final apiClient = ApiClient(sessionStorage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService(apiClient, sessionStorage))..bootstrap(),
        ),
        ChangeNotifierProxyProvider<AuthController, PurchaseController>(
          create: (_) => PurchaseController(PurchaseService(apiClient)),
          update: (_, authController, purchaseController) {
            final controller = purchaseController ?? PurchaseController(PurchaseService(apiClient));
            controller.bindSession(authController.user);
            return controller;
          },
        ),
        ChangeNotifierProvider(
          create: (_) => ReportesController(
            ReportesService(apiClient),
            VoiceService(apiClient),
          ),
        ),
      ],
      child: const SurtidorBoliviaMobileApp(),
    ),
  );
}

class SurtidorBoliviaMobileApp extends StatelessWidget {
  const SurtidorBoliviaMobileApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: AppConfig.appName,
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      onGenerateRoute: AppRouter.onGenerateRoute,
      initialRoute: AppRoutes.splash,
    );
  }
}
