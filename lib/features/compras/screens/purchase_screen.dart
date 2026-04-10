import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../shared/widgets/section_card.dart';
import '../models/fuel_catalog_item.dart';
import '../state/purchase_controller.dart';

class PurchaseScreen extends StatefulWidget {
  const PurchaseScreen({super.key});

  @override
  State<PurchaseScreen> createState() => _PurchaseScreenState();
}

class _PurchaseScreenState extends State<PurchaseScreen> {
  final _formKey = GlobalKey<FormState>();
  final _quantityController = TextEditingController();
  final _observationController = TextEditingController();
  String? _selectedFuelCode;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final controller = context.read<PurchaseController>();
      await controller.loadCatalog();
      if (!mounted) {
        return;
      }
      final first = controller.catalog.isNotEmpty ? controller.catalog.first.codigo : null;
      setState(() {
        _selectedFuelCode = _selectedFuelCode ?? first;
      });
    });
  }

  @override
  void dispose() {
    _quantityController.dispose();
    _observationController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate() || _selectedFuelCode == null) {
      return;
    }

    final controller = context.read<PurchaseController>();
    final success = await controller.registerPurchase(
      tipoCombustible: _selectedFuelCode!,
      cantidad: _quantityController.text,
      observacion: _observationController.text,
    );

    if (!mounted) {
      return;
    }

    if (success) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Compra registrada correctamente.')),
      );
      _quantityController.clear();
      _observationController.clear();
      await controller.loadPurchases();
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(controller.errorMessage ?? 'No se pudo registrar la compra.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    final controller = context.watch<PurchaseController>();
    final selectedFuel = controller.findByCode(_selectedFuelCode ?? '');
    final total = _calculateTotal(selectedFuel);

    return Scaffold(
      appBar: AppBar(title: const Text('Registrar compra')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          SectionCard(
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Compra de combustible',
                    style: Theme.of(context).textTheme.headlineSmall?.copyWith(fontWeight: FontWeight.w800),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'El precio unitario se obtiene del backend y el total se calcula automáticamente.',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 24),
                  DropdownButtonFormField<String>(
                    initialValue: selectedFuel?.codigo,
                    decoration: const InputDecoration(
                      labelText: 'Tipo de combustible',
                      prefixIcon: Icon(Icons.local_gas_station_rounded),
                    ),
                    items: controller.catalog
                        .map(
                          (item) => DropdownMenuItem<String>(
                            value: item.codigo,
                            child: Text(item.nombre),
                          ),
                        )
                        .toList(),
                    onChanged: controller.catalog.isEmpty
                        ? null
                        : (value) => setState(() => _selectedFuelCode = value),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _quantityController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    decoration: InputDecoration(
                      labelText: 'Cantidad',
                      prefixIcon: const Icon(Icons.scale_rounded),
                      suffixText: selectedFuel?.unidad ?? '',
                    ),
                    validator: (value) {
                      final amount = double.tryParse(value ?? '');
                      if (amount == null || amount <= 0) {
                        return 'Ingresa una cantidad válida.';
                      }
                      return null;
                    },
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _observationController,
                    maxLines: 3,
                    decoration: const InputDecoration(
                      labelText: 'Observación',
                      prefixIcon: Icon(Icons.notes_rounded),
                    ),
                  ),
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(18),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.06),
                      borderRadius: BorderRadius.circular(18),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Precio unitario: Bs ${selectedFuel?.precioUnitario.toStringAsFixed(2) ?? '0.00'}'),
                        const SizedBox(height: 6),
                        Text('Total estimado: Bs ${total.toStringAsFixed(2)}'),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton(
                    onPressed: controller.submitting ? null : _submit,
                    child: controller.submitting
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(strokeWidth: 2.5),
                          )
                        : const Text('Guardar compra'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  double _calculateTotal(FuelCatalogItem? selectedFuel) {
    final quantity = double.tryParse(_quantityController.text) ?? 0;
    final unitPrice = selectedFuel?.precioUnitario ?? 0;
    return quantity * unitPrice;
  }
}
