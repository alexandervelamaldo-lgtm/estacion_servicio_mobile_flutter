import '../../../core/network/api_client.dart';

/// Respuesta estructurada del asistente IA devuelta por el backend.
class AsistenteRespuesta {
  const AsistenteRespuesta({
    required this.respuesta,
    required this.intencion,
    required this.datos,
    required this.sugerencias,
  });

  final String respuesta;
  final String intencion;
  final Map<String, dynamic> datos;
  final List<String> sugerencias;

  factory AsistenteRespuesta.fromJson(Map<String, dynamic> json) {
    final textoRaw = json['respuesta'];
    final texto = textoRaw is String && textoRaw.trim().isNotEmpty
        ? textoRaw.trim()
        : 'No recibí una respuesta. Intenta reformular tu pregunta.';

    final datosRaw = json['datos'];
    final datos = datosRaw is Map
        ? Map<String, dynamic>.from(datosRaw)
        : <String, dynamic>{};

    final sugerenciasRaw = json['sugerencias'];
    final sugerencias = sugerenciasRaw is List
        ? sugerenciasRaw.map((e) => e.toString()).toList()
        : <String>[];

    return AsistenteRespuesta(
      respuesta: texto,
      intencion: json['intencion'] as String? ?? 'desconocido',
      datos: datos,
      sugerencias: sugerencias,
    );
  }
}

/// Servicio que consume el endpoint del asistente conversacional del backend.
///
/// Reutiliza EXACTAMENTE el mismo endpoint que la versión web
/// (`POST /reportes/asistente/`), por lo que el comportamiento y las
/// capacidades de las respuestas son idénticos (ventas, clientes, turnos,
/// combustibles, sucursales y predicciones).
class AsistenteService {
  AsistenteService(this._apiClient);

  final ApiClient _apiClient;

  /// Envía una pregunta en lenguaje natural junto al historial reciente.
  ///
  /// [historial] es una lista de mapas `{rol, contenido}` con los últimos
  /// turnos de la conversación, igual que en la versión web.
  Future<AsistenteRespuesta> preguntar(
    String pregunta, {
    List<Map<String, String>> historial = const <Map<String, String>>[],
  }) async {
    final response = await _apiClient.post(
      '/reportes/asistente/',
      body: {
        'pregunta': pregunta,
        'historial': historial,
      },
      authenticated: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException(
        'Respuesta del servidor inválida al consultar el asistente.',
      );
    }

    return AsistenteRespuesta.fromJson(response);
  }
}
