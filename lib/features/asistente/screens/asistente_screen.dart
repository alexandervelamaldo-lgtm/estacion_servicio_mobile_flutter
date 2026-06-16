import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../models/chat_message.dart';
import '../state/asistente_controller.dart';

/// Etiqueta legible para la intención detectada por el backend. Igual que la
/// versión web (`ETIQUETA_INTENCION` en `AsistenteIAModule.jsx`).
const Map<String, String> kEtiquetaIntencion = <String, String>{
  'ventas': 'Ventas',
  'combustible': 'Combustibles',
  'clientes': 'Clientes',
  'turnos': 'Turnos',
  'sucursales': 'Sucursales',
  'prediccion': 'Predicción',
  'desconocido': 'Ayuda',
};

/// Pantalla del asistente conversacional IA para móvil.
///
/// Replica las capacidades de la versión web (ventas, clientes, turnos,
/// combustibles, sucursales y predicciones) reutilizando el mismo backend,
/// con una interfaz de chat adaptada a pantallas móviles y alineada con la
/// identidad visual de la app (navy / verde).
class AsistenteScreen extends StatefulWidget {
  const AsistenteScreen({super.key});

  @override
  State<AsistenteScreen> createState() => _AsistenteScreenState();
}

class _AsistenteScreenState extends State<AsistenteScreen> {
  final TextEditingController _inputCtrl = TextEditingController();
  final ScrollController _scrollCtrl = ScrollController();

  @override
  void dispose() {
    _inputCtrl.dispose();
    _scrollCtrl.dispose();
    super.dispose();
  }

  void _scrollToBottom() {
    if (!_scrollCtrl.hasClients) {
      return;
    }
    _scrollCtrl.animateTo(
      _scrollCtrl.position.maxScrollExtent,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _enviar(AsistenteController controller, [String? texto]) {
    final pregunta = (texto ?? _inputCtrl.text).trim();
    if (pregunta.isEmpty || controller.loading) {
      return;
    }
    _inputCtrl.clear();
    controller.send(pregunta);
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<AsistenteController>();
    final messages = controller.messages;

    // Auto-desplazamiento al último mensaje en cada reconstrucción
    // (mensajes nuevos, indicador de carga o transcripción parcial).
    WidgetsBinding.instance.addPostFrameCallback((_) => _scrollToBottom());

    return Scaffold(
      appBar: AppBar(
        title: const Text('Asistente IA'),
        actions: [
          IconButton(
            tooltip: 'Nueva conversación',
            onPressed: controller.loading ? null : controller.clear,
            icon: const Icon(Icons.delete_sweep_rounded),
          ),
        ],
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: ListView.builder(
                controller: _scrollCtrl,
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
                itemCount: messages.length + (controller.loading ? 1 : 0),
                itemBuilder: (context, index) {
                  if (index >= messages.length) {
                    return const _TypingIndicator();
                  }
                  return _MessageBubble(message: messages[index]);
                },
              ),
            ),
            if (!controller.loading && controller.sugerenciasActivas.isNotEmpty)
              _SuggestionsRow(
                sugerencias: controller.sugerenciasActivas,
                onTap: (s) => _enviar(controller, s),
              ),
            if (controller.listening) _ListeningBar(partial: controller.partial),
            _InputBar(
              controller: _inputCtrl,
              listening: controller.listening,
              loading: controller.loading,
              onSend: () => _enviar(controller),
              onToggleVoice: controller.toggleVoice,
            ),
            const _Disclaimer(),
          ],
        ),
      ),
    );
  }
}

// ── Burbuja de mensaje ───────────────────────────────────────────────────

class _MessageBubble extends StatelessWidget {
  const _MessageBubble({required this.message});

  final ChatMessage message;

  @override
  Widget build(BuildContext context) {
    final maxWidth = MediaQuery.of(context).size.width * 0.78;

    if (message.isUser) {
      return Padding(
        padding: const EdgeInsets.only(bottom: 14),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.end,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Container(
                constraints: BoxConstraints(maxWidth: maxWidth),
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                decoration: const BoxDecoration(
                  color: AppTheme.primary,
                  borderRadius: BorderRadius.only(
                    topLeft: Radius.circular(18),
                    topRight: Radius.circular(4),
                    bottomLeft: Radius.circular(18),
                    bottomRight: Radius.circular(18),
                  ),
                ),
                child: SelectableText(
                  message.content,
                  style: const TextStyle(color: Colors.white, height: 1.35),
                ),
              ),
            ),
            const SizedBox(width: 10),
            const _UserAvatar(),
          ],
        ),
      );
    }

    final esError = message.isError;
    final chips = _resumenChips(message.intencion, message.datos);

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BotAvatar(),
          const SizedBox(width: 10),
          Flexible(
            child: ConstrainedBox(
              constraints: BoxConstraints(maxWidth: maxWidth),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (message.intencion != null && !esError)
                    _IntentBadge(intencion: message.intencion!),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: esError ? const Color(0xFFFEECEC) : Colors.white,
                      border: Border.all(
                        color: esError
                            ? const Color(0xFFF5C2C2)
                            : Colors.blueGrey.shade100,
                      ),
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(4),
                        topRight: Radius.circular(18),
                        bottomLeft: Radius.circular(18),
                        bottomRight: Radius.circular(18),
                      ),
                    ),
                    child: SelectableText(
                      message.content,
                      style: TextStyle(
                        color: esError
                            ? const Color(0xFFB42318)
                            : const Color(0xFF334155),
                        height: 1.4,
                      ),
                    ),
                  ),
                  if (chips.isNotEmpty && !esError) ...[
                    const SizedBox(height: 8),
                    Wrap(
                      spacing: 6,
                      runSpacing: 6,
                      children: chips
                          .map((e) => _DataChip(label: e.key, value: e.value))
                          .toList(),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _BotAvatar extends StatelessWidget {
  const _BotAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [AppTheme.secondary, Color(0xFF0F766E)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.all(Radius.circular(12)),
      ),
      child: const Icon(Icons.auto_awesome_rounded, color: Colors.white, size: 20),
    );
  }
}

class _UserAvatar extends StatelessWidget {
  const _UserAvatar();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 36,
      height: 36,
      decoration: BoxDecoration(
        color: Colors.blueGrey.shade100,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Icon(Icons.person_rounded, color: Colors.blueGrey.shade700, size: 20),
    );
  }
}

class _IntentBadge extends StatelessWidget {
  const _IntentBadge({required this.intencion});

  final String intencion;

  @override
  Widget build(BuildContext context) {
    final etiqueta = kEtiquetaIntencion[intencion] ?? intencion;
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
        decoration: BoxDecoration(
          color: AppTheme.secondary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Text(
          etiqueta.toUpperCase(),
          style: const TextStyle(
            color: Color(0xFF047857),
            fontSize: 10,
            fontWeight: FontWeight.w700,
            letterSpacing: 0.5,
          ),
        ),
      ),
    );
  }
}

class _DataChip extends StatelessWidget {
  const _DataChip({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.blueGrey.shade100),
        borderRadius: BorderRadius.circular(8),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(fontSize: 11, color: Color(0xFF64748B)),
          children: [
            TextSpan(text: '$label: '),
            TextSpan(
              text: value,
              style: const TextStyle(
                color: Color(0xFF334155),
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Indicador de "escribiendo" ─────────────────────────────────────────────

class _TypingIndicator extends StatelessWidget {
  const _TypingIndicator();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const _BotAvatar(),
          const SizedBox(width: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.blueGrey.shade100),
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(4),
                topRight: Radius.circular(18),
                bottomLeft: Radius.circular(18),
                bottomRight: Radius.circular(18),
              ),
            ),
            child: const Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                ),
                SizedBox(width: 10),
                Text(
                  'Analizando tus datos…',
                  style: TextStyle(color: Color(0xFF64748B)),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Sugerencias ─────────────────────────────────────────────────────────────

class _SuggestionsRow extends StatelessWidget {
  const _SuggestionsRow({required this.sugerencias, required this.onTap});

  final List<String> sugerencias;
  final ValueChanged<String> onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      alignment: Alignment.centerLeft,
      child: SingleChildScrollView(
        scrollDirection: Axis.horizontal,
        child: Row(
          children: [
            const Padding(
              padding: EdgeInsets.only(right: 8),
              child: Icon(Icons.lightbulb_outline_rounded,
                  size: 16, color: Color(0xFF94A3B8)),
            ),
            ...sugerencias.map(
              (s) => Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ActionChip(
                  label: Text(s),
                  labelStyle: const TextStyle(
                    fontSize: 12,
                    color: Color(0xFF047857),
                    fontWeight: FontWeight.w600,
                  ),
                  backgroundColor: AppTheme.secondary.withValues(alpha: 0.10),
                  side: BorderSide(color: AppTheme.secondary.withValues(alpha: 0.35)),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(20),
                  ),
                  onPressed: () => onTap(s),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Barra de escucha por voz ─────────────────────────────────────────────────

class _ListeningBar extends StatelessWidget {
  const _ListeningBar({required this.partial});

  final String partial;

  @override
  Widget build(BuildContext context) {
    final texto = partial.trim().isEmpty
        ? 'Escuchando… habla y haré la consulta automáticamente.'
        : partial;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      decoration: BoxDecoration(
        color: const Color(0xFFFEECEC),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: const Color(0xFFF5C2C2)),
      ),
      child: Row(
        children: [
          const Icon(Icons.mic_rounded, color: Color(0xFFB42318), size: 18),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(color: Color(0xFFB42318), fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}

// ── Barra de entrada ─────────────────────────────────────────────────────────

class _InputBar extends StatelessWidget {
  const _InputBar({
    required this.controller,
    required this.listening,
    required this.loading,
    required this.onSend,
    required this.onToggleVoice,
  });

  final TextEditingController controller;
  final bool listening;
  final bool loading;
  final VoidCallback onSend;
  final VoidCallback onToggleVoice;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: Colors.blueGrey.shade100)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              enabled: !listening,
              minLines: 1,
              maxLines: 5,
              keyboardType: TextInputType.multiline,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: InputDecoration(
                hintText: listening
                    ? 'Escuchando… habla ahora'
                    : 'Escribe tu pregunta…',
                contentPadding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
            ),
          ),
          const SizedBox(width: 8),
          _CircleIconButton(
            tooltip: listening ? 'Detener escucha' : 'Hablar (entrada por voz)',
            icon: listening ? Icons.mic_off_rounded : Icons.mic_rounded,
            background: listening
                ? const Color(0xFFB42318)
                : Colors.blueGrey.shade50,
            foreground: listening ? Colors.white : Colors.blueGrey.shade700,
            onPressed: loading ? null : onToggleVoice,
          ),
          const SizedBox(width: 8),
          ListenableBuilder(
            listenable: controller,
            builder: (context, _) {
              final puedeEnviar =
                  controller.text.trim().isNotEmpty && !loading && !listening;
              return _CircleIconButton(
                tooltip: 'Enviar',
                icon: Icons.send_rounded,
                background:
                    puedeEnviar ? AppTheme.secondary : Colors.blueGrey.shade200,
                foreground: Colors.white,
                onPressed: puedeEnviar ? onSend : null,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _CircleIconButton extends StatelessWidget {
  const _CircleIconButton({
    required this.tooltip,
    required this.icon,
    required this.background,
    required this.foreground,
    required this.onPressed,
  });

  final String tooltip;
  final IconData icon;
  final Color background;
  final Color foreground;
  final VoidCallback? onPressed;

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: tooltip,
      child: Material(
        color: background,
        shape: const CircleBorder(),
        child: InkWell(
          customBorder: const CircleBorder(),
          onTap: onPressed,
          child: SizedBox(
            width: 48,
            height: 48,
            child: Icon(icon, color: foreground, size: 22),
          ),
        ),
      ),
    );
  }
}

// ── Pie de página ─────────────────────────────────────────────────────────────

class _Disclaimer extends StatelessWidget {
  const _Disclaimer();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 0, 16, 10),
      child: Text(
        'Las respuestas se generan a partir de los datos reales de tu sucursal. '
        'Las predicciones son estimaciones basadas en el historial.',
        textAlign: TextAlign.center,
        style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade400),
      ),
    );
  }
}

// ── Resumen de datos (chips) ──────────────────────────────────────────────────

/// Construye cifras clave compactas para dar transparencia a la respuesta,
/// replicando la lógica de `DatosResumen` de la versión web y agregando el
/// caso de sucursales (resaltado en móvil).
List<MapEntry<String, String>> _resumenChips(
  String? intencion,
  Map<String, dynamic>? datos,
) {
  if (datos == null || datos.isEmpty) {
    return const [];
  }

  final chips = <MapEntry<String, String>>[];
  String bs(dynamic v) =>
      'Bs. ${NumberFormat('#,##0.00', 'es_BO').format(_num(v))}';
  String litros(dynamic v) =>
      '${NumberFormat('#,##0', 'es_BO').format(_num(v))} L';

  switch (intencion) {
    case 'ventas':
      if (datos['total_recaudado_bs'] != null) {
        chips.add(MapEntry('Recaudado', bs(datos['total_recaudado_bs'])));
      }
      if (datos['total_litros'] != null) {
        chips.add(MapEntry('Litros', litros(datos['total_litros'])));
      }
      if (datos['cantidad_ventas'] != null) {
        chips.add(MapEntry('Ventas', '${datos['cantidad_ventas']}'));
      }
      break;
    case 'combustible':
      final top = datos['combustible_top'];
      if (top is Map) {
        chips.add(MapEntry('Top', '${top['tipo_combustible']}'));
        chips.add(MapEntry('Total', bs(top['total'])));
      }
      break;
    case 'clientes':
      final top = datos['cliente_top'];
      if (top is Map) {
        chips.add(MapEntry('Top cliente', '${top['cliente']}'));
        chips.add(MapEntry('Consumo', bs(top['total_consumido_bs'])));
      }
      break;
    case 'turnos':
      if (datos['total_turnos'] != null) {
        chips.add(MapEntry('Turnos', '${datos['total_turnos']}'));
      }
      if (datos['turnos_abiertos'] != null) {
        chips.add(MapEntry('Abiertos', '${datos['turnos_abiertos']}'));
      }
      break;
    case 'sucursales':
      if (datos['total_sucursales'] != null) {
        chips.add(MapEntry('Sucursales', '${datos['total_sucursales']}'));
      }
      if (datos['sucursales_activas'] != null) {
        chips.add(MapEntry('Activas', '${datos['sucursales_activas']}'));
      }
      if (datos['sucursales_con_gnv'] != null) {
        chips.add(MapEntry('Con GNV', '${datos['sucursales_con_gnv']}'));
      }
      break;
    case 'prediccion':
      final resumen = datos['resumen'];
      if (resumen is Map) {
        if (resumen['total_estimado'] != null) {
          chips.add(MapEntry('Estimado', bs(resumen['total_estimado'])));
        }
        if (resumen['tendencia'] != null) {
          chips.add(MapEntry('Tendencia', '${resumen['tendencia']}'));
        }
      }
      break;
  }

  return chips;
}

num _num(dynamic v) {
  if (v is num) {
    return v;
  }
  return num.tryParse('$v') ?? 0;
}
