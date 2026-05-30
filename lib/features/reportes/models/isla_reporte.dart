/// Modelo de datos para el reporte de islas.
/// Representa la respuesta de `GET /api/reportes/islas/`.
class IslaReporte {
  const IslaReporte({
    required this.id,
    required this.numero,
    required this.sucursalNombre,
    required this.totalRecaudado,
    required this.totalLitros,
    required this.cantidadVentas,
    this.islaTop,
  });

  final int id;
  final int numero;
  final String sucursalNombre;
  final double totalRecaudado;
  final double totalLitros;
  final int cantidadVentas;

  /// La isla con más ventas. Puede ser `null` si no hay datos suficientes.
  final Map<String, dynamic>? islaTop;

  factory IslaReporte.fromJson(Map<String, dynamic> json) {
    return IslaReporte(
      id: json['id'] as int? ?? 0,
      numero: json['numero'] as int? ?? 0,
      sucursalNombre: json['sucursal_nombre'] as String? ?? '',
      totalRecaudado: (json['total_recaudado'] as num?)?.toDouble() ?? 0.0,
      totalLitros: (json['total_litros'] as num?)?.toDouble() ?? 0.0,
      cantidadVentas: json['cantidad_ventas'] as int? ?? 0,
      islaTop: json['isla_top'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'numero': numero,
      'sucursal_nombre': sucursalNombre,
      'total_recaudado': totalRecaudado,
      'total_litros': totalLitros,
      'cantidad_ventas': cantidadVentas,
      'isla_top': islaTop,
    };
  }
}
