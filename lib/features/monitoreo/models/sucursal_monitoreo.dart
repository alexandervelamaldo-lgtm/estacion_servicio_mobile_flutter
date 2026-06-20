class LadoMonitoreo {
  final int id;
  final String lado;
  final bool activo;
  final String estado;
  final String? descripcionFalla;

  const LadoMonitoreo({
    required this.id,
    required this.lado,
    required this.activo,
    required this.estado,
    this.descripcionFalla,
  });

  factory LadoMonitoreo.fromJson(Map<String, dynamic> json) {
    return LadoMonitoreo(
      id: json['id'] as int,
      lado: json['lado'].toString(),
      activo: json['activo'] as bool? ?? true,
      estado: json['estado'] as String? ?? 'ACTIVO',
      descripcionFalla: json['descripcion_falla'] as String?,
    );
  }
}

class IslaMonitoreo {
  final int id;
  final int numero;
  final String estado;
  final Map<String, dynamic>? turnoActivo;
  final List<LadoMonitoreo> lados;

  const IslaMonitoreo({
    required this.id,
    required this.numero,
    required this.estado,
    this.turnoActivo,
    required this.lados,
  });

  factory IslaMonitoreo.fromJson(Map<String, dynamic> json) {
    return IslaMonitoreo(
      id: json['id'] as int,
      numero: json['numero'] as int,
      estado: json['estado'] as String? ?? 'ACTIVO',
      turnoActivo: json['turno_activo'] as Map<String, dynamic>?,
      lados: (json['lados'] as List<dynamic>)
          .map((e) => LadoMonitoreo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}

class SucursalMonitoreo {
  final int sucursalId;
  final String sucursalNombre;
  final List<IslaMonitoreo> islas;

  const SucursalMonitoreo({
    required this.sucursalId,
    required this.sucursalNombre,
    required this.islas,
  });

  factory SucursalMonitoreo.fromJson(Map<String, dynamic> json) {
    return SucursalMonitoreo(
      sucursalId: json['sucursal_id'] as int,
      sucursalNombre: json['sucursal_nombre'] as String,
      islas: (json['islas'] as List<dynamic>)
          .map((e) => IslaMonitoreo.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
  }
}