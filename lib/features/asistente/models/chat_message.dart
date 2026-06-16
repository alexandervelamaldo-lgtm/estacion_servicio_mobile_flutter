/// Rol de un mensaje dentro de la conversación con el asistente.
enum ChatRole { usuario, asistente }

/// Un mensaje del chat del asistente IA.
class ChatMessage {
  const ChatMessage({
    required this.role,
    required this.content,
    this.intencion,
    this.datos,
    this.sugerencias = const <String>[],
    this.isError = false,
  });

  final ChatRole role;
  final String content;

  /// Intención detectada por el backend (ventas, sucursales, etc.).
  /// Solo presente en mensajes del asistente.
  final String? intencion;

  /// Datos estructurados devueltos por el backend para esta respuesta.
  final Map<String, dynamic>? datos;

  /// Sugerencias de seguimiento propuestas por el backend.
  final List<String> sugerencias;

  /// Indica que el mensaje representa un error (se muestra con estilo distinto).
  final bool isError;

  bool get isUser => role == ChatRole.usuario;
  bool get isAsistente => role == ChatRole.asistente;
}
