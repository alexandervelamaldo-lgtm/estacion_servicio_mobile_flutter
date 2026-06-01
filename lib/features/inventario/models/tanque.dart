class Tanque {
  final int id;
  final String tipoCombustible;
  final String sucursalNombre;
  final double capacidadMaxima;
  final double nivelActual;
  final double nivelMinimoAlerta;
  final bool enAlerta;
  final double porcentaje;

  const Tanque({
    required this.id,
    required this.tipoCombustible,
    required this.sucursalNombre,
    required this.capacidadMaxima,
    required this.nivelActual,
    required this.nivelMinimoAlerta,
    required this.enAlerta,
    required this.porcentaje,
  });

  factory Tanque.fromJson(Map<String, dynamic> json) {
    final capacidad = _toDouble(json['capacidad_maxima']);
    final nivel = _toDouble(json['nivel_actual']);
    final porcentaje = capacidad > 0 ? (nivel / capacidad) * 100 : 0.0;

    return Tanque(
      id: json['id'] as int,
      tipoCombustible: json['tipo_combustible_nombre'] as String? ??
          json['tipo_combustible'].toString(),
      sucursalNombre: json['sucursal_nombre'] as String? ??
          json['sucursal'].toString(),
      capacidadMaxima: capacidad,
      nivelActual: nivel,
      nivelMinimoAlerta: _toDouble(json['nivel_minimo_alerta']),
      enAlerta: json['en_alerta'] as bool? ?? false,
      porcentaje: porcentaje,
    );
  }

  static double _toDouble(dynamic value) {
    if (value == null) return 0.0;
    return double.tryParse(value.toString()) ?? 0.0;
  }
}