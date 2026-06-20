class DashboardData {
  const DashboardData({
    required this.kpis,
    required this.ventasPorTurno,
    required this.metodosPago,
    required this.rendimientoSurtidores,
    required this.estadoSurtidores,
  });

  final KpisPrincipales kpis;
  final List<VentaTurno> ventasPorTurno;
  final List<MetodoPago> metodosPago;
  final List<RendimientoSurtidor> rendimientoSurtidores;
  final Map<String, int> estadoSurtidores;

  factory DashboardData.fromJson(Map<String, dynamic> json) {
    return DashboardData(
      kpis: KpisPrincipales.fromJson(
          json['kpis_principales'] as Map<String, dynamic>? ?? {}),
      ventasPorTurno: (json['ventas_por_turno'] as List? ?? [])
          .map((e) => VentaTurno.fromJson(e as Map<String, dynamic>))
          .toList(),
      metodosPago: (json['metodos_pago'] as List? ?? [])
          .map((e) => MetodoPago.fromJson(e as Map<String, dynamic>))
          .toList(),
      rendimientoSurtidores: (json['rendimiento_surtidores'] as List? ?? [])
          .map((e) => RendimientoSurtidor.fromJson(e as Map<String, dynamic>))
          .toList(),
      estadoSurtidores: Map<String, int>.from(
          json['estado_surtidores'] as Map<String, dynamic>? ?? {}),
    );
  }
}

class KpisPrincipales {
  const KpisPrincipales({
    required this.ventasTotalesBs,
    required this.litrosVendidos,
    required this.margenGananciaBs,
    required this.promedioLitrosVenta,
  });

  final double ventasTotalesBs;
  final double litrosVendidos;
  final double margenGananciaBs;
  final double promedioLitrosVenta;

  factory KpisPrincipales.fromJson(Map<String, dynamic> json) {
    return KpisPrincipales(
      ventasTotalesBs: (json['ventas_totales_bs'] as num?)?.toDouble() ?? 0,
      litrosVendidos: (json['litros_vendidos'] as num?)?.toDouble() ?? 0,
      margenGananciaBs: (json['margen_ganancia_bs'] as num?)?.toDouble() ?? 0,
      promedioLitrosVenta:
          (json['promedio_litros_por_venta'] as num?)?.toDouble() ?? 0,
    );
  }
}

class VentaTurno {
  const VentaTurno({
    required this.turno,
    required this.totalBs,
    required this.litros,
  });

  final String turno;
  final double totalBs;
  final double litros;

  factory VentaTurno.fromJson(Map<String, dynamic> json) {
    return VentaTurno(
      turno: json['turno'] as String? ?? '',
      totalBs: (json['total_bs'] as num?)?.toDouble() ?? 0,
      litros: (json['litros'] as num?)?.toDouble() ?? 0,
    );
  }
}

class MetodoPago {
  const MetodoPago({
    required this.metodo,
    required this.totalBs,
    required this.porcentaje,
  });

  final String metodo;
  final double totalBs;
  final double porcentaje;

  factory MetodoPago.fromJson(Map<String, dynamic> json) {
    return MetodoPago(
      metodo: json['metodo'] as String? ?? '',
      totalBs: (json['total_bs'] as num?)?.toDouble() ?? 0,
      porcentaje: (json['porcentaje'] as num?)?.toDouble() ?? 0,
    );
  }
}

class RendimientoSurtidor {
  const RendimientoSurtidor({
    required this.surtidor,
    required this.litros,
  });

  final String surtidor;
  final double litros;

  factory RendimientoSurtidor.fromJson(Map<String, dynamic> json) {
    return RendimientoSurtidor(
      surtidor: json['surtidor'] as String? ?? '',
      litros: (json['litros'] as num?)?.toDouble() ?? 0,
    );
  }
}
