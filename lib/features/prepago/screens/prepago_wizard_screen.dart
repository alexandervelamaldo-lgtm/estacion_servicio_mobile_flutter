import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../core/theme/app_theme.dart';
import '../../compras/models/fuel_catalog_item.dart';
import '../state/prepago_controller.dart';

class PrepagoWizardScreen extends StatefulWidget {
  const PrepagoWizardScreen({super.key});

  @override
  State<PrepagoWizardScreen> createState() => _PrepagoWizardScreenState();
}

class _PrepagoWizardScreenState extends State<PrepagoWizardScreen>
    with TickerProviderStateMixin {
  final _montoController = TextEditingController();
  late AnimationController _fadeController;
  late Animation<double> _fadeAnimation;

  @override
  void initState() {
    super.initState();
    _fadeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _fadeAnimation = CurvedAnimation(
      parent: _fadeController,
      curve: Curves.easeInOut,
    );
    _fadeController.forward();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<PrepagoController>().loadCombustibles();
    });
  }

  @override
  void dispose() {
    _montoController.dispose();
    _fadeController.dispose();
    super.dispose();
  }

  void _animateStepChange() {
    _fadeController.reset();
    _fadeController.forward();
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PrepagoController>();
    final step = controller.currentStep;

    return Scaffold(
      appBar: AppBar(
        title: Text(_stepTitle(step)),
        leading: step > 0 && !controller.pagoExitoso
            ? IconButton(
                icon: const Icon(Icons.arrow_back_rounded),
                onPressed: () {
                  controller.previousStep();
                  _animateStepChange();
                },
              )
            : null,
      ),
      body: Column(
        children: [
          _buildProgressBar(step, controller.pagoExitoso),
          Expanded(
            child: FadeTransition(
              opacity: _fadeAnimation,
              child: _buildStepContent(controller),
            ),
          ),
        ],
      ),
    );
  }

  String _stepTitle(int step) {
    switch (step) {
      case 0:
        return 'Selecciona Combustible';
      case 1:
        return 'Pago Seguro';
      case 2:
        return '¡Compra Exitosa!';
      default:
        return 'Prepago';
    }
  }

  Widget _buildProgressBar(int step, bool success) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Row(
        children: List.generate(3, (index) {
          final isActive = index == step;
          final isCompleted = index < step || success;
          return Expanded(
            child: Row(
              children: [
                if (index > 0)
                  Expanded(
                    child: Container(
                      height: 3,
                      decoration: BoxDecoration(
                        color: isCompleted
                            ? AppTheme.secondary
                            : Colors.grey.shade200,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                AnimatedContainer(
                  duration: const Duration(milliseconds: 300),
                  width: isActive ? 36 : 28,
                  height: isActive ? 36 : 28,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: isCompleted
                        ? AppTheme.secondary
                        : isActive
                            ? AppTheme.primary
                            : Colors.grey.shade200,
                    boxShadow: isActive
                        ? [
                            BoxShadow(
                              color: AppTheme.primary.withValues(alpha: 0.3),
                              blurRadius: 8,
                              spreadRadius: 1,
                            ),
                          ]
                        : null,
                  ),
                  child: Center(
                    child: isCompleted
                        ? const Icon(Icons.check_rounded,
                            color: Colors.white, size: 18)
                        : Text(
                            '${index + 1}',
                            style: TextStyle(
                              color:
                                  isActive ? Colors.white : Colors.grey.shade500,
                              fontWeight: FontWeight.w700,
                              fontSize: 13,
                            ),
                          ),
                  ),
                ),
              ],
            ),
          );
        }),
      ),
    );
  }

  Widget _buildStepContent(PrepagoController controller) {
    switch (controller.currentStep) {
      case 0:
        return _buildStep1Selection(controller);
      case 1:
        return _buildStep2Payment(controller);
      case 2:
        return _buildStep3Confirmation(controller);
      default:
        return const SizedBox.shrink();
    }
  }

  // ═══════════════════════════════════════════════════
  //  PASO 1: Selección de combustible y monto
  // ═══════════════════════════════════════════════════

  Widget _buildStep1Selection(PrepagoController controller) {
    if (controller.isLoading && controller.combustibles.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Título
        Text(
          '¿Qué combustible deseas comprar?',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 16),

        // Grid de combustibles
        ...controller.combustibles.map((item) => _buildFuelTile(
              item,
              isSelected: controller.selectedCombustible == item,
              onTap: () => controller.selectCombustible(item),
            )),

        const SizedBox(height: 24),

        // Campo de monto
        Text(
          'Monto a pagar (Bs)',
          style: Theme.of(context)
              .textTheme
              .titleMedium
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 10),
        TextField(
          controller: _montoController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          inputFormatters: [
            FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d{0,2}')),
          ],
          decoration: InputDecoration(
            hintText: 'Ej: 100.00',
            prefixIcon: Container(
              padding: const EdgeInsets.all(14),
              child: const Text(
                'Bs',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 16,
                  color: AppTheme.primary,
                ),
              ),
            ),
            suffixIcon: _montoController.text.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear_rounded),
                    onPressed: () {
                      _montoController.clear();
                      controller.setMonto(0);
                    },
                  )
                : null,
          ),
          onChanged: (value) {
            controller.setMonto(double.tryParse(value) ?? 0);
          },
        ),
        const SizedBox(height: 20),

        // Resumen en vivo
        _buildLiveSummary(controller),

        const SizedBox(height: 24),

        // Error
        if (controller.errorMessage != null)
          _buildErrorBanner(controller.errorMessage!),

        // Botón continuar
        ElevatedButton.icon(
          onPressed: controller.montoIngresado > 0 &&
                  controller.selectedCombustible != null
              ? () async {
                  final success = await controller.crearOrden();
                  if (success && mounted) {
                    controller.nextStep();
                    _animateStepChange();
                  }
                }
              : null,
          icon: controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.arrow_forward_rounded),
          label: Text(
            controller.isLoading ? 'Creando orden...' : 'Continuar al Pago',
          ),
        ),
      ],
    );
  }

  Widget _buildFuelTile(
    FuelCatalogItem item, {
    required bool isSelected,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Material(
        color: isSelected
            ? AppTheme.secondary.withValues(alpha: 0.08)
            : Colors.white,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(20),
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 250),
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(20),
              border: Border.all(
                color: isSelected ? AppTheme.secondary : Colors.grey.shade200,
                width: isSelected ? 2 : 1,
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 48,
                  height: 48,
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: isSelected
                          ? [AppTheme.secondary, const Color(0xFF00A070)]
                          : [Colors.grey.shade100, Colors.grey.shade200],
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                    ),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Icon(
                    Icons.local_gas_station_rounded,
                    color: isSelected ? Colors.white : Colors.grey.shade500,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        item.nombre,
                        style: Theme.of(context).textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: isSelected
                                  ? AppTheme.primary
                                  : Colors.grey.shade800,
                            ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Bs ${item.precioUnitario.toStringAsFixed(2)} / ${item.unidad}',
                        style: TextStyle(
                          color: isSelected
                              ? AppTheme.secondary
                              : Colors.grey.shade500,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    padding: const EdgeInsets.all(4),
                    decoration: const BoxDecoration(
                      color: AppTheme.secondary,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.check_rounded,
                      color: Colors.white,
                      size: 18,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildLiveSummary(PrepagoController controller) {
    final litros = controller.litrosEstimados;
    final combustible = controller.selectedCombustible;

    return AnimatedContainer(
      duration: const Duration(milliseconds: 300),
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: litros > 0
            ? const LinearGradient(
                colors: [Color(0xFF081327), Color(0xFF153259)],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              )
            : null,
        color: litros > 0 ? null : Colors.grey.shade100,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Resumen',
                style: TextStyle(
                  color: litros > 0 ? Colors.white70 : Colors.grey.shade500,
                  fontWeight: FontWeight.w600,
                ),
              ),
              Icon(
                Icons.receipt_long_rounded,
                color: litros > 0 ? Colors.white30 : Colors.grey.shade300,
                size: 20,
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (combustible != null && litros > 0) ...[
            _summaryRow(
              'Combustible',
              combustible.nombre,
              litros > 0,
            ),
            const SizedBox(height: 6),
            _summaryRow(
              'Monto',
              'Bs ${controller.montoIngresado.toStringAsFixed(2)}',
              true,
            ),
            const SizedBox(height: 6),
            _summaryRow(
              'Litros estimados',
              '${litros.toStringAsFixed(2)} L',
              true,
              highlight: true,
            ),
          ] else
            Text(
              'Ingresa un monto para ver el resumen',
              style: TextStyle(
                color: Colors.grey.shade400,
                fontSize: 13,
              ),
            ),
        ],
      ),
    );
  }

  Widget _summaryRow(String label, String value, bool isDark,
      {bool highlight = false}) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: TextStyle(
            color: isDark ? Colors.white60 : Colors.grey.shade600,
          ),
        ),
        Text(
          value,
          style: TextStyle(
            color: isDark ? Colors.white : Colors.grey.shade800,
            fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
            fontSize: highlight ? 18 : 14,
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  PASO 2: Pago con Stripe
  // ═══════════════════════════════════════════════════

  Widget _buildStep2Payment(PrepagoController controller) {
    return ListView(
      padding: const EdgeInsets.all(20),
      children: [
        // Resumen compacto
        Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: AppTheme.secondary.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(Icons.local_gas_station_rounded,
                        color: AppTheme.secondary),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          controller.selectedCombustible?.nombre ?? '',
                          style:
                              Theme.of(context).textTheme.titleMedium?.copyWith(
                                    fontWeight: FontWeight.w700,
                                  ),
                        ),
                        Text(
                          '${controller.litrosEstimados.toStringAsFixed(2)} litros estimados',
                          style: TextStyle(color: Colors.grey.shade500),
                        ),
                      ],
                    ),
                  ),
                  Text(
                    'Bs ${controller.montoIngresado.toStringAsFixed(2)}',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                          color: AppTheme.primary,
                        ),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Información de pago seguro
        Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: Colors.grey.shade200),
          ),
          child: Column(
            children: [
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: const Color(0xFF635BFF).withValues(alpha: 0.08),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.credit_card_rounded,
                  color: Color(0xFF635BFF),
                  size: 40,
                ),
              ),
              const SizedBox(height: 16),
              Text(
                'Pago seguro con Stripe',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.w700,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Al presionar el botón de pago se abrirá la pantalla segura de Stripe donde podrás ingresar los datos de tu tarjeta.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.grey.shade500,
                  fontSize: 13,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 16),
              // Badges de seguridad
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.lock_rounded,
                      size: 14, color: Colors.grey.shade400),
                  const SizedBox(width: 6),
                  Text(
                    'Cifrado SSL · Stripe Secure',
                    style:
                        TextStyle(color: Colors.grey.shade400, fontSize: 12),
                  ),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 24),

        // Error
        if (controller.errorMessage != null)
          _buildErrorBanner(controller.errorMessage!),

        // Botón pagar
        ElevatedButton.icon(
          onPressed: controller.isLoading
              ? null
              : () async {
                  final success = await controller.confirmarPagoStripe();
                  if (success && mounted) {
                    _animateStepChange();
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color(0xFF635BFF), // Stripe purple
            minimumSize: const Size.fromHeight(56),
          ),
          icon: controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.payment_rounded),
          label: Text(
            controller.isLoading
                ? 'Procesando pago...'
                : 'Pagar Bs ${controller.montoIngresado.toStringAsFixed(2)}',
            style: const TextStyle(
              fontWeight: FontWeight.w700,
              fontSize: 16,
            ),
          ),
        ),
      ],
    );
  }

  // ═══════════════════════════════════════════════════
  //  PASO 3: Confirmación de éxito
  // ═══════════════════════════════════════════════════

  Widget _buildStep3Confirmation(PrepagoController controller) {
    return ListView(
      padding: const EdgeInsets.all(24),
      children: [
        const SizedBox(height: 20),
        // Ícono de éxito animado
        Center(
          child: TweenAnimationBuilder<double>(
            tween: Tween(begin: 0, end: 1),
            duration: const Duration(milliseconds: 600),
            curve: Curves.elasticOut,
            builder: (context, value, child) {
              return Transform.scale(
                scale: value,
                child: child,
              );
            },
            child: Container(
              width: 100,
              height: 100,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                gradient: const LinearGradient(
                  colors: [Color(0xFF00C989), Color(0xFF00A070)],
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppTheme.secondary.withValues(alpha: 0.35),
                    blurRadius: 24,
                    spreadRadius: 4,
                  ),
                ],
              ),
              child: const Icon(Icons.check_rounded,
                  color: Colors.white, size: 52),
            ),
          ),
        ),
        const SizedBox(height: 28),

        // Título
        Text(
          '¡Pago exitoso!',
          textAlign: TextAlign.center,
          style: Theme.of(context)
              .textTheme
              .headlineSmall
              ?.copyWith(fontWeight: FontWeight.w800),
        ),
        const SizedBox(height: 12),

        // Número de orden
        if (controller.numeroOrden != null)
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 20),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
            decoration: BoxDecoration(
              color: AppTheme.primary.withValues(alpha: 0.06),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Column(
              children: [
                Text(
                  'Orden',
                  style: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 13,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  controller.numeroOrden!,
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.w800,
                        color: AppTheme.primary,
                        letterSpacing: 1,
                      ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 20),

        // Info de validez
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 8),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: AppTheme.accent.withValues(alpha: 0.08),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppTheme.accent.withValues(alpha: 0.2),
            ),
          ),
          child: Row(
            children: [
              Icon(Icons.info_outline_rounded,
                  color: AppTheme.accent, size: 22),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  'Tu orden tiene validez de 24 horas. Presenta este comprobante en la estación.',
                  style: TextStyle(
                    color: Colors.orange.shade900,
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 28),

        // Botón PDF
        ElevatedButton.icon(
          onPressed: controller.isLoading
              ? null
              : () async {
                  if (controller.ordenId != null) {
                    await controller.descargarYCompartirPdf(controller.ordenId!);
                  }
                },
          style: ElevatedButton.styleFrom(
            backgroundColor: AppTheme.secondary,
            minimumSize: const Size.fromHeight(56),
          ),
          icon: controller.isLoading
              ? const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: Colors.white,
                  ),
                )
              : const Icon(Icons.picture_as_pdf_rounded),
          label: Text(
            controller.isLoading ? 'Descargando...' : 'Descargar Comprobante (PDF)',
            style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 16),
          ),
        ),
        const SizedBox(height: 14),

        // Botón volver
        OutlinedButton.icon(
          onPressed: () {
            controller.resetWizard();
            Navigator.pop(context);
          },
          icon: const Icon(Icons.home_rounded),
          label: const Text('Volver al inicio'),
          style: OutlinedButton.styleFrom(
            minimumSize: const Size.fromHeight(52),
          ),
        ),
      ],
    );
  }

  // ─── Helpers ───

  Widget _buildErrorBanner(String message) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.red.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.error_outline_rounded, color: Colors.red.shade400),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: Colors.red.shade700,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
