class AuthUser {
  const AuthUser({
    required this.id,
    required this.nombre,
    required this.email,
    required this.isActive,
    required this.isStaff,
    required this.isSuperuser,
  });

  final int id;
  final String nombre;
  final String email;
  final bool isActive;
  final bool isStaff;
  final bool isSuperuser;

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: json['id'] as int,
      nombre: json['nombre'] as String? ?? '',
      email: json['email'] as String? ?? '',
      isActive: json['is_active'] as bool? ?? false,
      isStaff: json['is_staff'] as bool? ?? false,
      isSuperuser: json['is_superuser'] as bool? ?? false,
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
    };
  }
}
