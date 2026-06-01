class AuthUser {
  const AuthUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
    this.empresaId,
    this.empresaNombre,
    this.sucursalId,
    this.sucursalNombre,
    this.rol,
  });

  final int id;
  final String nombre;
  final String email;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;
  final int? empresaId;
  final String? empresaNombre;
  final int? sucursalId;
  final String? sucursalNombre;
  final String? rol;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
   final rolesDetalle = json['roles_detalle'] as List?;
  final rol = rolesDetalle != null && rolesDetalle.isNotEmpty
      ? (rolesDetalle.first as Map<String, dynamic>)['nombre'].toString().toLowerCase()
      : null;

  return AuthUser(
    id: json['id'] as int,
    nombre: json['nombre'] as String? ?? '',
    email: json['email'] as String? ?? '',
    isActive: json['is_active'] as bool? ?? true,
    isStaff: json['is_staff'] as bool? ?? false,
    isSuperuser: json['is_superuser'] as bool? ?? false,
    empresaId: json['empresa_id'] as int?,
    empresaNombre: json['empresa_nombre'] as String?,
    sucursalId: json['sucursal_id'] as int?,
    sucursalNombre: json['sucursal_nombre'] as String?,
    rol: rol,
  );
}

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre': nombre,
      'email': email,
      'is_active': isActive,
      'is_staff': isStaff,
      'is_superuser': isSuperuser,
      'empresa_id': empresaId,
      'empresa_nombre': empresaNombre,
      'sucursal_id': sucursalId,
      'sucursal_nombre': sucursalNombre,
      'rol': rol,
    };
  }
}