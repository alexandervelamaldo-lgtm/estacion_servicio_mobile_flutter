class Purchase {
  const Purchase({
    required this.id,
    required this.tipoCombustible,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
    required this.total,
    required this.fechaHora,
    required this.observacion,
    required this.combustibleNombre,
  });

  final int id;
  final String tipoCombustible;
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final double total;
  final DateTime fechaHora;
  final String observacion;
  final String combustibleNombre;

  factory Purchase.fromJson(Map<String, dynamic> json) {
    final detalle = json['combustible_detalle'] as Map<String, dynamic>? ?? const {};

    return Purchase(
      id: json['id'] as int,
      tipoCombustible: json['tipo_combustible'] as String? ?? '',
      cantidad: double.tryParse(json['cantidad'].toString()) ?? 0,
      unidad: json['unidad'] as String? ?? '',
      precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0,
      total: double.tryParse(json['total'].toString()) ?? 0,
      fechaHora: DateTime.tryParse(json['fecha_hora'] as String? ?? '') ?? DateTime.now(),
      observacion: json['observacion'] as String? ?? '',
      combustibleNombre: detalle['nombre'] as String? ?? '',
    );
  }
}
