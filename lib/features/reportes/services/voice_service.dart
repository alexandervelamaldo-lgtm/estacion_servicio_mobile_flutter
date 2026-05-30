import 'dart:async';

import 'package:speech_to_text/speech_to_text.dart' as stt;

import '../../../core/network/api_client.dart';

/// Resultado de la interpretación del comando de voz por el backend.
class VoiceCommandResult {
  const VoiceCommandResult({
    required this.tipoReporte,
    required this.filtros,
    required this.mensajeOriginal,
  });

  /// Tipo de reporte identificado: ventas, turnos, clientes, etc.
  final String tipoReporte;

  /// Filtros inferidos por el backend (fecha_inicio, fecha_fin, etc.)
  final Map<String, dynamic> filtros;

  /// Texto original reconocido por voz.
  final String mensajeOriginal;

  factory VoiceCommandResult.fromJson(Map<String, dynamic> json) {
    Map<String, dynamic> parsedFiltros = const {};
    if (json['filtros'] is Map<String, dynamic>) {
      parsedFiltros = json['filtros'] as Map<String, dynamic>;
    } else if (json['filtros'] is Map) {
      parsedFiltros = Map<String, dynamic>.from(json['filtros'] as Map);
    }
    
    return VoiceCommandResult(
      tipoReporte: json['tipo_reporte'] as String? ?? 'ventas',
      filtros: parsedFiltros,
      mensajeOriginal: json['mensaje_original'] as String? ?? '',
    );
  }
}

/// Estados posibles del asistente de voz.
enum VoiceState { idle, listening, processing, success, error }

/// Servicio que encapsula reconocimiento de voz e interpretación del comando
/// a través del backend.
class VoiceService {
  VoiceService(this._apiClient);

  final ApiClient _apiClient;
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _isAvailable = false;

  bool get isAvailable => _isAvailable;

  /// Inicializa el engine de reconocimiento de voz.
  /// Retorna `true` si el micrófono está disponible.
  Future<bool> initialize() async {
    _isAvailable = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _isAvailable;
  }

  /// Comienza a escuchar. Invoca [onResult] con el texto parcial/final reconocido.
  /// Invoca [onDone] cuando el engine deja de escuchar automáticamente.
  Future<void> startListening({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    if (!_isAvailable) {
      throw ApiException('El reconocimiento de voz no está disponible en este dispositivo.');
    }

    await _speech.listen(
      onResult: (result) {
        onResult(result.recognizedWords, result.finalResult);
      },
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        autoPunctuation: true,
        listenFor: const Duration(seconds: 15),
        pauseFor: const Duration(seconds: 3),
      ),
    );

    // Schedule a delayed check — speech_to_text calls onDone via status callback.
    _speech.statusListener = (status) {
      if (status == 'done' || status == 'notListening') {
        onDone();
      }
    };
  }

  /// Detiene manualmente la escucha.
  Future<void> stopListening() async {
    await _speech.stop();
  }

  /// Envía el texto reconocido al backend para interpretación del comando.
  /// Retorna un [VoiceCommandResult] con el tipo de reporte y filtros.
  Future<VoiceCommandResult> interpretarComando(String texto) async {
    final response = await _apiClient.post(
      '/reportes/interpretar/',
      body: {'texto': texto},
      authenticated: true,
    );

    if (response is! Map<String, dynamic>) {
      throw ApiException('Respuesta del servidor inválida al interpretar el comando.');
    }

    return VoiceCommandResult.fromJson(response);
  }
}
