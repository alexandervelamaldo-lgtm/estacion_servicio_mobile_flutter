class FuelCatalogItem {
  const FuelCatalogItem({
    required this.codigo,
    required this.nombre,
    required this.precioUnitario,
    required this.unidad,
  });

  final String codigo;
  final String nombre;
  final double precioUnitario;
  final String unidad;

  factory FuelCatalogItem.fromJson(Map<String, dynamic> json) {
    return FuelCatalogItem(
      codigo: json['codigo'] as String? ?? '',
      nombre: json['nombre'] as String? ?? '',
      precioUnitario: double.tryParse(json['precio_unitario'].toString()) ?? 0,
      unidad: json['unidad'] as String? ?? '',
    );
  }
}
