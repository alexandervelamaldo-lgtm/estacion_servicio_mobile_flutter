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
  static const String emulatorBaseUrl = 'http://192.168.1.8:8000/api';
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
  return 'https://backend-176137264021.us-central1.run.app/api';
    case AppEnvironment.development:
      return emulatorBaseUrl; // http://10.0.2.2:8000/api
  }
}

  static String get environmentName {
    return environment == AppEnvironment.production ? 'production' : 'development';
  }
}
