import 'package:estacion_servicio_mobile_flutter/core/network/api_client.dart';
import 'package:estacion_servicio_mobile_flutter/core/storage/session_storage.dart';
import 'package:estacion_servicio_mobile_flutter/features/auth/models/auth_user.dart';
import 'package:estacion_servicio_mobile_flutter/features/compras/models/purchase.dart';
import 'package:estacion_servicio_mobile_flutter/features/compras/services/purchase_service.dart';
import 'package:estacion_servicio_mobile_flutter/features/compras/state/purchase_controller.dart';
import 'package:flutter_test/flutter_test.dart';

class FakePurchaseService extends PurchaseService {
  FakePurchaseService() : super(ApiClient(SessionStorage()));

  List<Purchase> purchasesToReturn = const [];

  @override
  Future<List<Purchase>> getPurchases() async => purchasesToReturn;
}

void main() {
  const fer = AuthUser(
    id: 1,
    nombre: 'fer',
    email: 'fer.prueba@example.com',
    isActive: true,
    isStaff: false,
    isSuperuser: false,
  );

  const alex = AuthUser(
    id: 2,
    nombre: 'alexander',
    email: 'alex.prueba@example.com',
    isActive: true,
    isStaff: false,
    isSuperuser: false,
  );

  final ferPurchase = Purchase(
    id: 10,
    tipoCombustible: 'GASOLINA_PREMIUM',
    cantidad: 54.545,
    unidad: 'Lt',
    precioUnitario: 11,
    total: 600,
    fechaHora: DateTime(2026, 5, 16, 7, 28),
    observacion: '',
    combustibleNombre: 'Gasolina Premium',
  );

  test('cambiar de sesion limpia el historial anterior', () async {
    final service = FakePurchaseService();
    final controller = PurchaseController(service);

    controller.bindSession(fer);
    service.purchasesToReturn = [ferPurchase];
    await controller.loadPurchases();

    expect(controller.purchases, hasLength(1));
    expect(controller.purchases.first.id, 10);

    controller.bindSession(alex);

    expect(controller.purchases, isEmpty);
    expect(controller.lastHistorySyncAt, isNull);
    expect(controller.errorMessage, isNull);
  });

  test('sin sesion activa no conserva historial cargado', () async {
    final service = FakePurchaseService();
    final controller = PurchaseController(service);

    controller.bindSession(fer);
    service.purchasesToReturn = [ferPurchase];
    await controller.loadPurchases();

    expect(controller.purchases, hasLength(1));

    controller.bindSession(null);
    await controller.loadPurchases();

    expect(controller.purchases, isEmpty);
    expect(controller.lastHistorySyncAt, isNull);
  });
}
