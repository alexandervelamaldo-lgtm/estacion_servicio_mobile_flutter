class UserProfile {
  const UserProfile({
    required this.id,
    required this.nombre,
    required this.email,
    this.rol,
    this.nitCi,
    this.telefono,
    this.placa,
    this.marca,
    this.modelo,
    this.color,
  });

  final int id;
  final String nombre;
  final String email;
  final String? rol;
  final String? nitCi;
  final String? telefono;
  final String? placa;
  final String? marca;
  final String? modelo;
  final String? color;

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    return UserProfile(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      rol: json['rol'] as String?,
      nitCi: json['nit_ci'] as String?,
      telefono: json['telefono'] as String?,
      placa: json['placa'] as String?,
      marca: json['marca'] as String?,
      modelo: json['modelo'] as String?,
      color: json['color'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'nombre': nombre,
      'nit_ci': nitCi,
      'telefono': telefono,
      'placa': placa,
      'marca': marca,
      'modelo': modelo,
      'color': color,
    };
  }

  UserProfile copyWith({
    String? nombre,
    String? nitCi,
    String? telefono,
    String? placa,
    String? marca,
    String? modelo,
    String? color,
  }) {
    return UserProfile(
      id: id,
      email: email,
      rol: rol,
      nombre: nombre ?? this.nombre,
      nitCi: nitCi ?? this.nitCi,
      telefono: telefono ?? this.telefono,
      placa: placa ?? this.placa,
      marca: marca ?? this.marca,
      modelo: modelo ?? this.modelo,
      color: color ?? this.color,
    );
  }
}
