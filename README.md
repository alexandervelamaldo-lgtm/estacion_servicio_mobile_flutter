# Estacion Servicio Mobile Flutter

Aplicacion movil Flutter para SurtidorBolivia conectada al backend Django del proyecto.

## Requisitos
- Flutter SDK compatible con Dart `>=3.4.0 <4.0.0`
- Android Studio o VS Code
- Emulador Android o dispositivo fisico
- Backend local disponible

## Instalacion
1. Entra a la carpeta del proyecto:

```powershell
cd "D:\si2\3er sprint\estacion_servicio_mobile_flutter-main\estacion_servicio_mobile_flutter-main"
```

2. Instala dependencias:

```powershell
flutter pub get
```

3. Verifica dispositivos disponibles:

```powershell
flutter devices
```

## Configuracion De Variables De Entorno
Este proyecto no usa un archivo `.env` tradicional. La configuracion de entorno se realiza con `--dart-define`.

Las variables disponibles estan definidas en:
- [app_config.dart](file:///d:/si2/3er%20sprint/estacion_servicio_mobile_flutter-main/estacion_servicio_mobile_flutter-main/lib/core/config/app_config.dart)

## Variables Disponibles
- `APP_ENV`: define el entorno. Valores esperados: `development` o `production`.
- `API_BASE_URL`: URL base explicita de la API. Si no se envia, la app usa un valor por defecto segun el entorno.

## Valores Por Defecto
- Desarrollo:
  - `APP_ENV=development`
  - `API_BASE_URL` vacia
  - base URL por defecto: `http://10.0.2.2:8000/api`
- Produccion:
  - `APP_ENV=production`
  - base URL por defecto: `https://api.surtidorbolivia.com/api`

## Ejecucion Local En Emulador Android
Si usas el backend local en tu misma PC, primero levanta Django con:

```powershell
py -3.13 manage.py runserver 0.0.0.0:8000
```

Luego ejecuta Flutter:

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://10.0.2.2:8000/api
```

`10.0.2.2` es la IP especial que el emulador Android usa para acceder al `localhost` de tu PC.

## Ejecucion Local En Dispositivo Fisico
Si pruebas desde un telefono real, reemplaza `10.0.2.2` por la IP local de tu computadora:

```powershell
flutter run --dart-define=APP_ENV=development --dart-define=API_BASE_URL=http://192.168.1.10:8000/api
```

Ambos dispositivos deben estar conectados a la misma red.

## Ejecucion Sin Variables Explicitas
Si no envias `API_BASE_URL`, la app tomara los valores definidos en `app_config.dart`.

```powershell
flutter run
```

Esto funciona bien en emulador Android siempre que el backend este disponible en `http://10.0.2.2:8000/api`.

## Build Y Verificacion
- Analisis:

```powershell
flutter analyze
```

- Pruebas:

```powershell
flutter test
```

## Solucion De Problemas
- `No supported devices connected`: inicia el emulador o conecta un telefono y vuelve a ejecutar `flutter devices`.
- La app no conecta al backend: confirma `API_BASE_URL` y que Django corra en `0.0.0.0:8000`.
- En emulador no funciona `localhost`: usa `10.0.2.2`.
- En telefono fisico no funciona `10.0.2.2`: usa la IP local real de tu PC.
