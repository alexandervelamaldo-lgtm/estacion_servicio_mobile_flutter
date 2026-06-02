import 'package:flutter/material.dart';

import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/screens/splash_screen.dart';
import '../../features/compras/screens/home_screen.dart';
import '../../features/compras/screens/purchase_history_screen.dart';
import '../../features/compras/screens/purchase_screen.dart';
import '../../features/prepago/screens/prepago_history_screen.dart';
import '../../features/prepago/screens/prepago_wizard_screen.dart';
import '../../features/reportes/screens/reportes_screen.dart';

class AppRoutes {
  static const splash = '/';
  static const login = '/login';
  static const register = '/register';
  static const home = '/home';
  static const purchase = '/purchase';
  static const history = '/history';
  static const reportes = '/reportes';
  static const prepago = '/prepago';
  static const prepagoHistory = '/prepago-history';
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
      case AppRoutes.prepago:
        return MaterialPageRoute(builder: (_) => const PrepagoWizardScreen());
      case AppRoutes.prepagoHistory:
        return MaterialPageRoute(builder: (_) => const PrepagoHistoryScreen());
      default:
        return MaterialPageRoute(builder: (_) => const SplashScreen());
    }
  }
}

