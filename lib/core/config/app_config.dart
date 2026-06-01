import 'package:flutter/foundation.dart' show kIsWeb;

enum AppEnvironment { development, production }

class AppConfig {
  static const String appName = 'SurtidorBolivia Beta';
  static const String _environmentValue = String.fromEnvironment(
    'APP_ENV',
    defaultValue: 'development',
  );
  static const String _explicitBaseUrl = String.fromEnvironment(
    'API_BASE_URL',
    defaultValue: '',
  );
  static const String emulatorBaseUrl = 'http://10.0.2.2:8000/api';
  static const String localNetworkExample = 'http://192.168.1.10:8000/api';

  static AppEnvironment get environment {
    switch (_environmentValue) {
      case 'production':
        return AppEnvironment.production;
      default:
        return AppEnvironment.development;
    }
  }

  static String get baseUrl {
    if (_explicitBaseUrl.isNotEmpty) {
      return _explicitBaseUrl;
    }

    switch (environment) {
      case AppEnvironment.production:
        return 'https://api.surtidorbolivia.com/api';
      case AppEnvironment.development:
        // En web (flutter run -d chrome) usar localhost en vez de 10.0.2.2
        return kIsWeb ? 'http://localhost:8000/api' : emulatorBaseUrl;
    }
  }

  static String get environmentName {
    return environment == AppEnvironment.production ? 'production' : 'development';
  }
}
