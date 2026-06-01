import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:onesignal_flutter/onesignal_flutter.dart';

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
import 'features/monitoreo/services/monitoreo_service.dart';
import 'features/monitoreo/state/monitoreo_controller.dart';
import 'features/inventario/services/inventario_service.dart';
import 'features/inventario/state/inventario_controller.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  OneSignal.initialize('c1ec0c61-fb3a-4c87-8667-1107a403ed11');
await OneSignal.Notifications.requestPermission(true);
final state = await OneSignal.Notifications.permission;
print('OneSignal permission state: $state');

  final sessionStorage = SessionStorage();
  final apiClient = ApiClient(sessionStorage);

  runApp(
    MultiProvider(
      providers: [
        ChangeNotifierProvider(
          create: (_) => AuthController(AuthService(apiClient, sessionStorage))
            ..bootstrap(),
        ),
        ChangeNotifierProxyProvider<AuthController, PurchaseController>(
          create: (_) => PurchaseController(PurchaseService(apiClient)),
          update: (_, authController, purchaseController) {
            final controller = purchaseController ??
                PurchaseController(PurchaseService(apiClient));
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
        // Dentro de MultiProvider, agrega:
        ChangeNotifierProvider(
          create: (_) => MonitoreoController(MonitoreoService(apiClient)),
        ),
        ChangeNotifierProvider(
          create: (_) => InventarioController(InventarioService(apiClient)),
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
