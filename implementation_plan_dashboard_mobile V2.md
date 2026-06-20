# Plan de Implementación: Navegación Principal, Dashboard y Perfil (Mobile)

Este plan detalla la reestructuración de la navegación de la aplicación móvil mediante una Barra de Navegación Inferior (*Bottom Navigation Bar*), la implementación del Dashboard para roles administrativos y la creación de la vista "Mi Perfil" basada en el frontend web.

> [!NOTE]
> Este plan es conceptual para guiar el desarrollo en Flutter. No se modificará código directamente en la carpeta de la aplicación en este paso.

---

## 1. Rediseño de Navegación (Bottom Navigation Bar)

La vista inicial (`home_screen.dart`) se convertirá en parte de un contenedor principal (`MainLayout`) que tendrá un `BottomNavigationBar`. Las opciones (pestañas) mostradas dependerán del rol del usuario:

### Pestañas para el Cliente:
1. **Home:** Mantiene la vista principal actual (bienvenida y combustibles disponibles), pero **se eliminará** la sección de "Acciones rápidas" y el botón de "Mis compras prepago" para limpiar la pantalla.
2. **Mis compras:** Se moverá la vista del historial de compras prepago (antes accesible por botón) a esta pestaña dedicada.
3. **Mi perfil (Nuevo):** Una nueva pantalla equivalente a la de la web para gestionar los datos de usuario, facturación (NIT/CI) y datos del vehículo (Placa, Marca, Modelo, Color).

### Pestañas para Administrador / Gerente:
1. **Dashboard:** Será el equivalente al Home pero enfocado en métricas, mostrando los KPIs principales y gráficos de la empresa o sucursal (usando el plan anterior).
2. **Reportes:** La funcionalidad del botón actual de reportes se moverá a esta pestaña.
3. **Monitoreo de sucursales:** Se moverá la funcionalidad de monitoreo a esta pestaña.
4. **Control de combustible:** Se moverá la funcionalidad de control a esta pestaña.

---

## 2. Endpoints a Consumir y JSON de Ejemplo

### A. Mi Perfil
El módulo de perfil consumirá los mismos endpoints que usa el frontend en React (`clientesService.js`).

- **Obtener Perfil:** `GET /api/usuarios/me/`
- **Actualizar Perfil:** `PATCH /api/usuarios/me/`

**Ejemplo JSON de Respuesta / Envío:**
```json
{
  "id": 1,
  "nombre": "Juan Perez",
  "email": "juan@example.com",
  "rol": "cliente",
  "nit_ci": "1234567",
  "telefono": "77712345",
  "placa": "ABC-1234",
  "marca": "Toyota",
  "modelo": "Corolla",
  "color": "Blanco"
}
```

### B. Dashboard Ejecutivo
- **Endpoint:** `GET /api/dashboard/kpis/`
- **Parámetros Query:** `?fecha_inicio=YYYY-MM-DD&fecha_fin=YYYY-MM-DD`

**Ejemplo JSON de Respuesta:**
```json
{
  "kpis_principales": {
    "ventas_totales_bs": 150450.50,
    "litros_vendidos": 42000.00,
    "margen_ganancia_bs": 25000.75,
    "promedio_litros_venta": 35.5
  },
  "ventas_por_turno": [
    { "turno": "Mañana", "total_bs": 60000.00, "total_litros": 16000.00 },
    { "turno": "Tarde", "total_bs": 50000.00, "total_litros": 14000.00 },
    { "turno": "Noche", "total_bs": 40450.50, "total_litros": 12000.00 }
  ],
  "metodos_pago": [
    { "metodo": "Efectivo", "total_bs": 90000.00, "cantidad_transacciones": 1500 },
    { "metodo": "Tarjeta", "total_bs": 40000.00, "cantidad_transacciones": 600 },
    { "metodo": "QR", "total_bs": 20450.50, "cantidad_transacciones": 450 }
  ],
  "rendimiento_surtidores": [
    { "surtidor": "Isla 1 - Lado A", "total_bs": 80000.00, "total_litros": 22000.00 },
    { "surtidor": "Isla 1 - Lado B", "total_bs": 70450.50, "total_litros": 20000.00 }
  ],
  "estado_surtidores": [
    { "estado": "Activo", "cantidad": 6 },
    { "estado": "En Mantenimiento", "cantidad": 1 },
    { "estado": "Inactivo", "cantidad": 0 }
  ]
}
```

---

## 3. Cambios Propuestos (Arquitectura Flutter)

### A. Layout Principal (`lib/features/home/screens/main_layout.dart`)
- Crear un nuevo widget `MainLayout` que contenga un `Scaffold` con un `BottomNavigationBar`.
- La lista de `BottomNavigationBarItem` y las pantallas (`body`) a mostrar se generarán dinámicamente evaluando `authController.user.rol` para mostrar el menú de Cliente o el menú de Administrador.

### B. Refactorización del Home (`lib/features/compras/screens/home_screen.dart`)
- **[MODIFY]** Eliminar la sección "Acciones rápidas" (que contiene el botón "Mis compras prepago" y "Reportes"). Estos accesos se moverán a la barra inferior.
- **[MODIFY]** Retirar el AppBar si se maneja globalmente en el `MainLayout`.

### C. Nuevo Módulo: Perfil (`lib/features/perfil/`)
- **Modelos:** `user_profile_model.dart` con los métodos `fromJson` y `toJson`.
- **Servicios:** `profile_service.dart` con métodos para hacer GET y PATCH a `/api/usuarios/me/`.
- **UI (`screens/profile_screen.dart`):** Un formulario estilizado similar al web que permita editar Nombre, Contraseña (opcional), NIT/CI, Teléfono y datos obligatorios del vehículo (Placa, Marca, Modelo, Color).
- **Controlador (`state/profile_controller.dart`):** Manejará los estados de carga y errores al actualizar el perfil.

### D. Nuevo Módulo: Dashboard (`lib/features/dashboard/`)
- **Modelos:** `dashboard_model.dart`.
- **Servicios:** `dashboard_service.dart`.
- **UI (`screens/dashboard_screen.dart`):** Scroll vertical (`SingleChildScrollView`). Incluirá tarjetas (KPI Cards) usando un `GridView` y gráficos (Ventas por Turno, Métodos de Pago) implementados con la librería `fl_chart`. Los filtros de fecha se abrirán desde un icono en el AppBar mediante un `showModalBottomSheet`.

---

## 4. Verification Plan

1. **Navegación por Roles:** Iniciar sesión como Cliente y verificar que la barra inferior muestra *Home, Mis compras y Mi perfil*. Cerrar sesión, ingresar como Administrador y verificar que muestra *Dashboard, Reportes, Monitoreo y Control*.
2. **Edición de Perfil:** En la pestaña "Mi perfil", enviar una actualización de la placa y verificar que los cambios persistan tras reiniciar la app (verificando la respuesta del backend).
3. **Visualización de Dashboard:** Validar que los gráficos y KPIs carguen la información correcta mediante llamadas a la API y que los filtros de fecha actualicen los componentes de la interfaz.
