/// Modelo de datos para el reporte de sucursales.
/// Representa la respuesta de `GET /api/reportes/sucursales/`.
class SucursalReporte {
  const SucursalReporte({
    required this.id,
    required this.nombre,
    required this.direccion,
    required this.totalRecaudado,
    required this.totalLitros,
    required this.cantidadTurnos,
    required this.cantidadIslas,
  });

  final int id;
  final String nombre;
  final String direccion;
  final double totalRecaudado;
  final double totalLitros;

  /// Cantidad de turnos históricos registrados en esta sucursal.
  final int cantidadTurnos;
  final int cantidadIslas;

  factory SucursalReporte.fromJson(Map<String, dynamic> json) {
    return SucursalReporte(
      id: json['id'] as int? ?? 0,
      nombre: json['nombre'] as String? ?? '',
      direccion: json['direccion'] as String? ?? '',
      totalRecaudado: (json['total_recaudado'] as num?)?.toDouble() ?? 0.0,
      totalLitros: (json['total_litros'] as num?)?.toDouble() ?? 0.0,
      cantidadTurnos: json['cantidad_turnos'] as int? ?? 0,
      cantidadIslas: json['cantidad_islas'] as int? ?? 0,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'direccion': direccion,
      'total_recaudado': totalRecaudado,
      'total_litros': totalLitros,
      'cantidad_turnos': cantidadTurnos,
      'cantidad_islas': cantidadIslas,
    };
  }
}
