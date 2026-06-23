# MOTOLINK — Arquitectura

Proyecto académico tipo InDrive para mototaxis, basado en **negociación de
tarifas** entre pasajero y conductor.

Este documento describe la arquitectura **tal como está implementada**, no
un plan. El proyecto es funcional de extremo a extremo: la app móvil
consume el backend real (sin datos mock) mediante
`core/di/service_locator.dart`, la negociación viaja por REST + Socket.IO,
login/calificación persisten contra la base de datos, y GPS (`geolocator`)
y gestión de estado (`Provider`) están integrados. Ver
[VERIFICACION_EJECUCION.md](VERIFICACION_EJECUCION.md) para el detalle de
lo verificado en ejecución contra el emulador, y
`python manage.py test` / `flutter test` para las pruebas automatizadas.

---

## 1. Stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter / Dart, `go_router`, `provider`, `socket_io_client`, `geolocator` |
| Backend | Django 5 + DRF, autenticación por sesión (no JWT), `python-socketio` sobre eventlet (WebSocket real) |
| Base de datos | SQLite |
| Arquitectura | Clean Architecture (domain / data / presentation) en ambos lados |

```
MOTOLINK/
├── backend/   # API REST + Socket.IO (Django)
├── mobile/    # App Flutter
└── docs/      # Esta documentación
```

---

## 2. Clean Architecture en el frontend (`mobile/lib/`)

```
lib/
├── core/                      → Código transversal, sin lógica de negocio
│   ├── constants/             → Endpoints de la API
│   ├── di/                    → service_locator.dart: punto de composición manual
│   ├── enums/                 → Estados (EstadoSolicitud, EstadoViaje, EstadoOferta, TipoOferta, RolUsuario)
│   ├── error/                 → ServerException, mensajeDeError()
│   ├── location/              → LocationService + LocationCalculos (geolocator)
│   ├── network/                → ApiClient (http + cookie de sesión manual)
│   ├── realtime/              → SocketService, eventos y salas de Socket.IO
│   ├── routing/                → app_routes.dart, app_router.dart (go_router)
│   └── theme/                  → Tema Material de la app
│
└── features/
    └── <feature>/
        ├── domain/             → entities/, repositories/ (contratos), usecases/
        ├── data/               → models/ (fromJson/toJson), datasources/, repositories/ (impl)
        └── presentation/       → pages/, providers/ (solo auth usa Provider; el resto maneja
                                  su estado con StatefulWidget directamente)
```

### Regla de dependencia

```
presentation  →  domain  ←  data
```

`domain` no importa Flutter ni `data`. `data` implementa los contratos de
`domain`. `presentation` consume usecases a través de `ServiceLocator`.

### Features implementados

| Feature | Responsabilidad |
|---|---|
| `auth` | Login, registro de pasajero/conductor, sesión (`AuthProvider`) |
| `onboarding` | Splash |
| `profile` | Perfil y datos del vehículo del conductor (`Mototaxista`) |
| `trip_request` | Pasajero define origen (GPS opcional)/destino y tarifa propuesta |
| `negotiation` | Ofertas, contraofertas, aceptación/rechazo/selección |
| `trip_tracking` | Viaje asignado / en curso, finalizar, seguimiento GPS en vivo |
| `trip_history` | Historial de viajes (pasajero y conductor) |
| `rating` | Calificación 1-5 al finalizar el viaje |
| `driver_home` | Pantalla principal del conductor, notificación de nuevas solicitudes |
| `passenger_home` | Pantalla principal del pasajero, notificación de ofertas |
| `admin` | Dashboard, gestión de usuarios, listas de pasajeros/conductores |

`chat`, `wallet`, `support` y `notifications` no forman parte del MVP — ver
[BACKLOG.md](BACKLOG.md) para el detalle y el orden de prioridad si se
retoman.

---

## 3. Rutas reales (`core/routing/app_routes.dart`, `go_router`)

```
/splash
/role-selection
/login/:rol
/registro-pasajero
/registro-mototaxista
/passenger/home
/passenger/crear-solicitud
/passenger/proponer-tarifa
/passenger/ofertas/:solicitudId
/passenger/conductor-seleccionado
/passenger/viaje-en-curso/:viajeId
/passenger/calificacion/:viajeId
/passenger/historial
/driver/home
/driver/solicitudes
/driver/contraoferta/:solicitudId
/driver/viaje-asignado/:viajeId
/driver/historial
/admin/dashboard
/admin/usuarios
/admin/conductores
/admin/pasajeros
```

---

## 4. Gestión de estado

`AuthProvider` (`ChangeNotifier`) es el único provider de la app: mantiene
la sesión del usuario autenticado y se inyecta vía
`ChangeNotifierProvider` en `main.dart`. El resto de pantallas maneja su
propio estado de carga/error/datos con `StatefulWidget` + `setState`,
usando `AsyncStateView<T>` (`shared/widgets/async_state_view.dart`) como
patrón compartido para no repetir la misma cascada de
cargando/error/vacío/datos en cada pantalla con listas.

---

## 5. Clean Architecture en el backend (`backend/`)

```
backend/
├── backend/        → settings.py (config por entorno vía .env), urls.py, wsgi.py
├── core/            → SesionUsuarioAuthentication, realtime (Socket.IO: server, events, notifier)
└── <app>/
    ├── domain/          → Excepciones de negocio (ej. OfertaDuplicadaError)
    ├── application/     → usecases/ y services/ (NegotiationService)
    ├── infrastructure/  → models.py, serializers.py, migrations/, repositories.py
    └── presentation/    → views.py (ViewSets DRF), urls.py
```

### Apps reales

| App | Responsabilidad |
|---|---|
| `users` | `Usuario`, `Mototaxista`; login/logout/me, registro, listados |
| `trips` | `SolicitudViaje`, `Viaje`; creación, historial, viaje activo, finalizar |
| `negotiation` | `Oferta`; aceptar/contraofertar/rechazar/seleccionar vía `NegotiationService` |
| `ratings` | `Calificacion` (1-5, una por viaje) |
| `core` | Autenticación por sesión, Socket.IO (servidor, eventos, notificador) |

### Tiempo real (Socket.IO)

| Sala | Quién se suscribe | Eventos |
|---|---|---|
| `conductores` | Todo conductor conectado (pantalla de inicio o lista de solicitudes) | `SolicitudCreada` |
| `solicitud_<id>` | Quien esté viendo "Ofertas recibidas" de esa solicitud | `OfertaCreada`, `ContraOfertaCreada` |
| `usuario_<id>` | El propio pasajero/conductor, desde cualquier pantalla | `OfertaCreada`, `ContraOfertaCreada` (pasajero), `ViajeAsignado` (ambos) |

### Regla de dependencia

```
presentation (views DRF)  →  application (usecases/services)  →  domain
                                       ↑
                               infrastructure (modelos ORM, serializers)
```

---

## 6. Configuración por entorno

`backend/backend/settings.py` lee `DJANGO_SECRET_KEY`, `DJANGO_DEBUG` y
`DJANGO_ALLOWED_HOSTS` desde variables de entorno (`backend/.env`, no
versionado — ver `backend/.env.example`), con defaults seguros para
desarrollo local si no existe `.env`.

---

## 7. Pruebas automatizadas

- **Backend** (`python manage.py test`): flujo completo de negociación,
  duplicidad de ofertas, validación de calificación, historial para ambas
  partes, login/registro/sesión, casos de concurrencia entre conductores
  y entradas inexistentes (404 controlado, no 500).
- **Mobile** (`flutter test`): parsing de modelos contra la forma real del
  JSON del backend (decimales como `num`, snake_case, contraseña ausente).
