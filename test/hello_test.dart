import 'package:flutter_test/flutter_test.dart';
import 'package:estacion_servicio_mobile_flutter/features/auth/models/auth_user.dart';

void main() {
  test('AuthUser convierte JSON a modelo', () {
    final user = AuthUser.fromJson({
      'id': 1,
      'nombre': 'Alex',
      'email': 'alex@example.com',
      'is_active': true,
      'is_staff': false,
      'is_superuser': false,
    });

    expect(user.nombre, 'Alex');
    expect(user.email, 'alex@example.com');
    expect(user.isActive, isTrue);
  });
}
