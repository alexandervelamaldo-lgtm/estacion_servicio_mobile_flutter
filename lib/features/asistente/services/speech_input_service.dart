import 'package:speech_to_text/speech_to_text.dart' as stt;

/// Envoltorio sencillo de reconocimiento de voz (speech-to-text) para el
/// asistente. Es independiente del backend: solo transcribe voz a texto, de
/// modo que el asistente sea utilizable también con micrófono (paridad con el
/// botón de voz de la versión web).
class SpeechInputService {
  final stt.SpeechToText _speech = stt.SpeechToText();

  bool _available = false;

  bool get isAvailable => _available;
  bool get isListening => _speech.isListening;

  /// Inicializa el motor de voz. Devuelve `true` si el micrófono está listo.
  Future<bool> initialize() async {
    _available = await _speech.initialize(
      onError: (_) {},
      onStatus: (_) {},
    );
    return _available;
  }

  /// Comienza a escuchar. [onResult] recibe el texto reconocido (parcial y
  /// final); [onDone] se invoca cuando el motor deja de escuchar.
  Future<void> start({
    required void Function(String text, bool isFinal) onResult,
    required void Function() onDone,
  }) async {
    if (!_available) {
      return;
    }

    await _speech.listen(
      onResult: (result) => onResult(
        result.recognizedWords,
        result.finalResult,
      ),
      listenOptions: stt.SpeechListenOptions(
        listenMode: stt.ListenMode.dictation,
        cancelOnError: true,
        autoPunctuation: true,
        listenFor: const Duration(seconds: 20),
        pauseFor: const Duration(seconds: 3),
      ),
    );

    _speech.statusListener = (status) {
      if (status == 'done' || status == 'notListening') {
        onDone();
      }
    };
  }

  /// Detiene la escucha manualmente.
  Future<void> stop() async {
    await _speech.stop();
  }
}
