import 'package:flutter/material.dart';

import '../../features/asistente/screens/asistente_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/compras/screens/home_screen.dart';
import '../../features/compras/screens/purchase_history_screen.dart';
import '../../features/compras/screens/purchase_screen.dart';
import '../../features/reportes/screens/reportes_screen.dart';
import '../../features/dashboard/screens/admin_dashboard_screen.dart';
import '../../features/monitoreo/screens/monitoreo_screen.dart';
import '../../features/inventario/screens/inventario_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const purchase = '/purchase';
  static const history = '/history';
  static const reportes = '/reportes';
  static const monitoreo = '/monitoreo';
  static const adminDashboard = '/dashboard';
  static const inventario = '/inventario';
  static const asistente = '/asistente';
}

class AppRouter {
  static Route<dynamic> onGenerateRoute(RouteSettings settings) {
    switch (settings.name) {
      case AppRoutes.splash:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
      case AppRoutes.login:
        return MaterialPageRoute(builder: (_) => const LoginScreen());
      case AppRoutes.register:
        return MaterialPageRoute(builder: (_) => const RegisterScreen());
      case AppRoutes.home:
        return MaterialPageRoute(builder: (_) => const HomeScreen());
      case AppRoutes.purchase:
        return MaterialPageRoute(builder: (_) => const PurchaseScreen());
      case AppRoutes.history:
        return MaterialPageRoute(builder: (_) => const PurchaseHistoryScreen());
      case AppRoutes.reportes:
        return MaterialPageRoute(builder: (_) => const ReportesScreen());
      case AppRoutes.monitoreo:
        return MaterialPageRoute(builder: (_) => const MonitoreoScreen());
      case AppRoutes.adminDashboard:
       return MaterialPageRoute(builder: (_) => const AdminDashboardScreen());
       case AppRoutes.inventario:
        return MaterialPageRoute(builder: (_) => const InventarioScreen());
      case AppRoutes.asistente:
        return MaterialPageRoute(builder: (_) => const AsistenteScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}
