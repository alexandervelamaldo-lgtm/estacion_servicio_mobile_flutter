import 'package:flutter/foundation.dart';

class PrepagoOrden {
  const PrepagoOrden({
    required this.id,
    required this.numeroOrden,
    required this.tipoCombustibleNombre,
    required this.montoTotal,
    required this.litrosEstimados,
    required this.estado,
    required this.fechaCreacion,
    this.clientSecret,
  });

  final int id;
  final String numeroOrden;
  final String tipoCombustibleNombre;
  final double montoTotal;
  final double litrosEstimados;
  final String estado;
  final DateTime fechaCreacion;
  final String? clientSecret;

  factory PrepagoOrden.fromJson(Map<String, dynamic> json) {
    // Para ver exactamente qué campos envía el backend en consola
    debugPrint('PrepagoOrden JSON: $json'); 
    
    return PrepagoOrden(
      id: json['id'] as int? ?? 0,
      numeroOrden: json['numero_orden'] as String? ?? '',
      tipoCombustibleNombre: json['tipo_combustible_nombre'] as String? ??
          json['tipo_combustible'] as String? ??
          '',
      montoTotal: double.tryParse(json['monto_total'].toString()) ?? 0,
      litrosEstimados:
          double.tryParse(json['litros_estimados']?.toString() ?? 
                          json['cantidad_estimada']?.toString() ?? 
                          json['cantidad']?.toString() ?? 
                          json['litros']?.toString() ?? 
                          '0') ?? 0,
      estado: json['estado'] as String? ?? 'PENDIENTE',
      fechaCreacion: DateTime.tryParse(
              json['fecha_creacion'] as String? ?? '') ??
          DateTime.now(),
      clientSecret: json['client_secret'] as String?,
    );
  }

  /// Color-coded status label for UI chips.
  static String estadoLabel(String estado) {
    switch (estado.toUpperCase()) {
      case 'PAGADO':
        return 'Pagado';
      case 'DESPACHADO':
        return 'Despachado';
      case 'EXPIRADO':
        return 'Expirado';
      case 'PENDIENTE':
        return 'Pendiente';
      default:
        return estado;
    }
  }
}
