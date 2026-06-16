import 'package:flutter/foundation.dart';

import '../../../core/network/api_client.dart';
import '../../auth/models/auth_user.dart';
import '../models/chat_message.dart';
import '../services/asistente_service.dart';
import '../services/speech_input_service.dart';

/// Sugerencias mostradas al abrir el asistente. Incluyen sucursales, en
/// paridad con las capacidades de la versión web.
const List<String> kSugerenciasIniciales = <String>[
  '¿Cuántas sucursales tiene la empresa?',
  '¿Dónde están ubicadas las sucursales?',
  '¿Cuánto vendí esta semana?',
  'Predice mi demanda de mañana',
];

/// Texto del mensaje de bienvenida (refleja todas las capacidades del
/// asistente, igual que la versión web).
const String kMensajeBienvenida =
    '¡Hola! 👋 Soy tu asistente de inteligencia de negocio. Puedo responder '
    'preguntas sobre tus ventas, clientes, turnos, combustibles, sucursales y '
    'predicciones de demanda. Pregúntame en lenguaje natural, por ejemplo: '
    '"¿cuántas sucursales tiene la empresa?".';

ChatMessage _mensajeBienvenida() => const ChatMessage(
      role: ChatRole.asistente,
      content: kMensajeBienvenida,
      sugerencias: kSugerenciasIniciales,
    );

/// Controla el estado del asistente IA: historial de chat, carga, errores y
/// entrada por voz. Mantiene paridad funcional con la versión web reutilizando
/// el mismo backend.
class AsistenteController extends ChangeNotifier {
  AsistenteController(this._service, this._speech);

  final AsistenteService _service;
  final SpeechInputService _speech;

  final List<ChatMessage> _messages = <ChatMessage>[_mensajeBienvenida()];
  bool _loading = false;
  bool _listening = false;
  String _partial = '';
  String? _error;
  String? _sessionUserEmail;

  List<ChatMessage> get messages => List.unmodifiable(_messages);
  bool get loading => _loading;
  bool get listening => _listening;
  String get partial => _partial;
  String? get error => _error;

  /// Sugerencias activas = las del último mensaje del asistente que las tenga.
  List<String> get sugerenciasActivas {
    for (var i = _messages.length - 1; i >= 0; i--) {
      final m = _messages[i];
      if (m.isAsistente && m.sugerencias.isNotEmpty) {
        return m.sugerencias;
      }
    }
    return kSugerenciasIniciales;
  }

  /// Privacidad: si cambia el usuario autenticado, se reinicia la conversación
  /// para no exponer el historial de otra sesión.
  void bindSession(AuthUser? user) {
    final nextEmail = user?.email.trim().toLowerCase();
    if (_sessionUserEmail == nextEmail) {
      return;
    }
    _sessionUserEmail = nextEmail;
    _reset(notify: true);
  }

  /// Limpia la conversación manualmente (botón "Nueva conversación").
  void clear() => _reset(notify: true);

  void _reset({required bool notify}) {
    _messages
      ..clear()
      ..add(_mensajeBienvenida());
    _loading = false;
    _listening = false;
    _partial = '';
    _error = null;
    if (notify) {
      notifyListeners();
    }
  }

  /// Envía una pregunta al asistente y agrega la respuesta al historial.
  Future<void> send(String texto) async {
    final pregunta = texto.trim();
    if (pregunta.isEmpty || _loading) {
      return;
    }

    // Historial = conversación previa (sin incluir la pregunta nueva).
    final historial = _historialParaBackend();

    _messages.add(ChatMessage(role: ChatRole.usuario, content: pregunta));
    _loading = true;
    _partial = '';
    _error = null;
    notifyListeners();

    try {
      final res = await _service.preguntar(pregunta, historial: historial);
      _messages.add(
        ChatMessage(
          role: ChatRole.asistente,
          content: res.respuesta,
          intencion: res.intencion,
          datos: res.datos,
          sugerencias: res.sugerencias,
        ),
      );
    } on ApiException catch (e) {
      _error = e.message;
      _messages.add(
        ChatMessage(role: ChatRole.asistente, content: e.message, isError: true),
      );
    } catch (_) {
      const msg =
          'Ocurrió un error al consultar el asistente. Intenta de nuevo.';
      _error = msg;
      _messages.add(
        const ChatMessage(
          role: ChatRole.asistente,
          content: msg,
          isError: true,
        ),
      );
    } finally {
      _loading = false;
      notifyListeners();
    }
  }

  /// Construye los últimos 6 turnos (sin la bienvenida ni los mensajes de
  /// error) como mapas `{rol, contenido}`, igual que la versión web.
  List<Map<String, String>> _historialParaBackend() {
    final hist = <Map<String, String>>[];
    for (var i = 0; i < _messages.length; i++) {
      if (i == 0) {
        // Saltar el mensaje de bienvenida (no es parte del diálogo real).
        continue;
      }
      final m = _messages[i];
      if (m.isError) {
        continue;
      }
      hist.add({
        'rol': m.isUser ? 'usuario' : 'asistente',
        'contenido': m.content,
      });
    }
    if (hist.length <= 6) {
      return hist;
    }
    return hist.sublist(hist.length - 6);
  }

  // ── Entrada por voz ──────────────────────────────────────────────────

  /// Alterna la escucha por voz (iniciar/detener).
  Future<void> toggleVoice() async {
    if (_listening) {
      await stopVoice();
    } else {
      await startVoice();
    }
  }

  Future<void> startVoice() async {
    if (_loading || _listening) {
      return;
    }
    final ok = await _speech.initialize();
    if (!ok) {
      _error = 'El micrófono no está disponible en este dispositivo.';
      notifyListeners();
      return;
    }
    _listening = true;
    _partial = '';
    _error = null;
    notifyListeners();

    await _speech.start(
      onResult: (text, isFinal) {
        if (!_listening) {
          return;
        }
        _partial = text;
        notifyListeners();
        if (isFinal && text.trim().isNotEmpty) {
          _finalizarYEnviar();
        }
      },
      onDone: _finalizarYEnviar,
    );
  }

  Future<void> stopVoice() async {
    await _speech.stop();
    _finalizarYEnviar();
  }

  /// Cierra la escucha y envía lo capturado (si hay texto). Protegido para que
  /// solo el primer disparo (resultado final, fin del motor o stop manual)
  /// produzca un envío.
  void _finalizarYEnviar() {
    if (!_listening) {
      return;
    }
    _listening = false;
    final pendiente = _partial.trim();
    notifyListeners();
    if (pendiente.isNotEmpty) {
      send(pendiente);
    }
  }

  @override
  void dispose() {
    _speech.stop();
    super.dispose();
  }
}
