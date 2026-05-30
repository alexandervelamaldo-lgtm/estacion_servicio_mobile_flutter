import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../core/theme/app_theme.dart';
import '../services/voice_service.dart';
import '../state/reportes_controller.dart';

/// Modal de asistente de voz presentado como BottomSheet.
/// Muestra estados visuales: idle → listening → processing → success / error.
class VoiceAssistantModal extends StatefulWidget {
  const VoiceAssistantModal({super.key});

  /// Muestra el modal. Retorna `true` si se aplicó un comando con éxito.
  static Future<bool?> show(BuildContext context) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => const VoiceAssistantModal(),
    );
  }

  @override
  State<VoiceAssistantModal> createState() => _VoiceAssistantModalState();
}

class _VoiceAssistantModalState extends State<VoiceAssistantModal>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController;
  late final Animation<double> _pulseAnimation;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 1200),
    )..repeat(reverse: true);
    _pulseAnimation = Tween<double>(begin: 1.0, end: 1.25).animate(
      CurvedAnimation(parent: _pulseController, curve: Curves.easeInOut),
    );

    // Auto-init voice when the modal opens.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _initAndListen();
    });
  }

  Future<void> _initAndListen() async {
    final controller = context.read<ReportesController>();
    final available = await controller.initVoice();
    if (!available && mounted) {
      controller.resetVoice();
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Micrófono no disponible en este dispositivo.')),
      );
      Navigator.pop(context, false);
      return;
    }
    if (mounted) {
      controller.startListening();
    }
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<ReportesController>();
    final state = controller.voiceState;

    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 32),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Drag handle
          Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),
          const SizedBox(height: 24),

          // Title
          Text(
            _title(state),
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w800),
          ),
          const SizedBox(height: 8),
          Text(
            _subtitle(state, controller),
            textAlign: TextAlign.center,
            style: Theme.of(context)
                .textTheme
                .bodyMedium
                ?.copyWith(color: Colors.grey.shade600),
          ),
          const SizedBox(height: 32),

          // Animated microphone / progress / result icon
          _buildCenterIcon(state, controller),

          const SizedBox(height: 24),

          // Recognized text
          if (controller.recognizedText.isNotEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppTheme.background,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Text(
                '"${controller.recognizedText}"',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: AppTheme.primary,
                    ),
              ),
            ),

          const SizedBox(height: 24),

          // Action buttons
          _buildActions(state, controller),
        ],
      ),
    );
  }

  // ── Helpers ──────────────────────────────────────────────────────────

  String _title(VoiceState state) {
    switch (state) {
      case VoiceState.idle:
        return 'Asistente de Voz';
      case VoiceState.listening:
        return 'Escuchando…';
      case VoiceState.processing:
        return 'Procesando…';
      case VoiceState.success:
        return '¡Comando recibido!';
      case VoiceState.error:
        return 'Error';
    }
  }

  String _subtitle(VoiceState state, ReportesController controller) {
    switch (state) {
      case VoiceState.idle:
        return 'Presiona el micrófono para comenzar.';
      case VoiceState.listening:
        return 'Diga su comando, por ejemplo:\n"Generar reporte de ventas de hoy"';
      case VoiceState.processing:
        return 'Interpretando su solicitud…';
      case VoiceState.success:
        final result = controller.lastVoiceResult;
        if (result != null) {
          return 'Reporte: ${result.tipoReporte.toUpperCase()}';
        }
        return 'Se aplicó el reporte.';
      case VoiceState.error:
        return controller.voiceError ?? 'Ocurrió un error inesperado.';
    }
  }

  Widget _buildCenterIcon(VoiceState state, ReportesController controller) {
    switch (state) {
      case VoiceState.idle:
        return _micButton(controller);
      case VoiceState.listening:
        return AnimatedBuilder(
          animation: _pulseAnimation,
          builder: (context, child) {
            return Transform.scale(
              scale: _pulseAnimation.value,
              child: _micButton(controller, listening: true),
            );
          },
        );
      case VoiceState.processing:
        return const SizedBox(
          height: 80,
          width: 80,
          child: CircularProgressIndicator(strokeWidth: 3, color: AppTheme.secondary),
        );
      case VoiceState.success:
        return Container(
          height: 80,
          width: 80,
          decoration: const BoxDecoration(
            shape: BoxShape.circle,
            color: AppTheme.secondary,
          ),
          child: const Icon(Icons.check_rounded, size: 40, color: Colors.white),
        );
      case VoiceState.error:
        return Container(
          height: 80,
          width: 80,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: Colors.red.shade400,
          ),
          child: const Icon(Icons.error_outline_rounded, size: 40, color: Colors.white),
        );
    }
  }

  Widget _micButton(ReportesController controller, {bool listening = false}) {
    return GestureDetector(
      onTap: () {
        if (listening) {
          controller.stopListening();
        } else {
          controller.startListening();
        }
      },
      child: Container(
        height: 80,
        width: 80,
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          gradient: LinearGradient(
            colors: listening
                ? [Colors.red.shade400, Colors.red.shade600]
                : [AppTheme.primary, const Color(0xFF153259)],
          ),
          boxShadow: [
            BoxShadow(
              color: (listening ? Colors.red : AppTheme.primary).withValues(alpha: 0.3),
              blurRadius: 20,
              spreadRadius: 2,
            ),
          ],
        ),
        child: Icon(
          listening ? Icons.stop_rounded : Icons.mic_rounded,
          size: 36,
          color: Colors.white,
        ),
      ),
    );
  }

  Widget _buildActions(VoiceState state, ReportesController controller) {
    if (state == VoiceState.success) {
      return Row(
        children: [
          Expanded(
            child: OutlinedButton(
              onPressed: () {
                controller.resetVoice();
              },
              child: const Text('Nuevo comando'),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text('Ver reporte'),
            ),
          ),
        ],
      );
    }

    if (state == VoiceState.error) {
      return SizedBox(
        width: double.infinity,
        child: ElevatedButton.icon(
          onPressed: () {
            controller.resetVoice();
            controller.startListening();
          },
          icon: const Icon(Icons.refresh_rounded),
          label: const Text('Reintentar'),
        ),
      );
    }

    if (state == VoiceState.listening) {
      return SizedBox(
        width: double.infinity,
        child: TextButton(
          onPressed: () {
            controller.stopListening();
            Navigator.pop(context, false);
          },
          child: const Text('Cancelar'),
        ),
      );
    }

    return const SizedBox.shrink();
  }
}
