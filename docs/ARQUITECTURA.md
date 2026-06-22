# MOTOLINK — Arquitectura Inicial

Proyecto académico tipo InDrive para mototaxis, basado en **negociación de tarifas** entre pasajero y conductor.

Esta etapa define únicamente la **estructura del proyecto** (Clean Architecture). No hay lógica funcional implementada todavía.

---

## 1. Visión general del stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter + Dart |
| Backend | Django (API REST con DRF) |
| Base de datos | SQLite |
| Arquitectura | Clean Architecture (Presentation / Domain / Data) |
| IA de apoyo | Cursor, Claude, Antigravity |

El repositorio tiene dos sub-proyectos independientes que se comunican por HTTP/REST:

```
MOTOLINK/
├── frontend/motolink_app/   → App Flutter (cliente)
└── backend/motolink_backend/ → API Django (servidor)
```

---

## 2. Clean Architecture en el Frontend (Flutter)

Cada **feature** (módulo funcional) replica las 3 capas de Clean Architecture de forma aislada. Esto permite que cada módulo se desarrolle, testee y reemplace sin afectar a los demás.

```
lib/
├── core/                     → Código transversal, sin lógica de negocio
│   ├── constants/            → Valores fijos: colores, endpoints, strings, tarifas mínimas
│   ├── error/                → Clases de error/Failure compartidas (ej. ServerFailure, NetworkFailure)
│   ├── network/              → Cliente HTTP base (Dio/http), interceptores, manejo de conectividad
│   ├── theme/                → Tema visual de la app (colores, tipografías, estilos Material)
│   ├── utils/                → Funciones auxiliares puras (formatters, validators)
│   ├── widgets/               → Widgets reutilizables sin lógica de negocio (botones, loaders, dialogs)
│   └── routing/              → Definición de rutas/navegación global de la app
│
└── features/
    └── <feature>/
        ├── domain/            → Reglas de negocio puras, sin Flutter ni paquetes externos
        │   ├── entities/      → Objetos de negocio (ej. Trip, Offer, User)
        │   ├── repositories/  → Contratos abstractos (interfaces) que Data debe implementar
        │   └── usecases/      → Una clase por acción de negocio (ej. SendTripOffer)
        │
        ├── data/              → Implementación concreta del acceso a datos
        │   ├── models/        → DTOs que extienden las entidades (fromJson/toJson)
        │   ├── datasources/   → Llamadas reales a la API Django (remote) o caché local (local)
        │   └── repositories/  → Implementación concreta de los contratos del domain
        │
        └── presentation/      → Todo lo que el usuario ve e interactúa
            ├── pages/         → Pantallas (screens) del feature
            ├── widgets/       → Widgets específicos de este feature (no reutilizables fuera)
            └── providers/     → Manejo de estado (Provider/Riverpod) que conecta UI ↔ domain
```

### Regla de dependencia (Clean Architecture)

```
presentation  →  domain  ←  data
```

* `domain` no conoce a nadie (no importa Flutter, no importa `data`, no importa `presentation`).
* `data` depende de `domain` (implementa sus interfaces).
* `presentation` depende de `domain` (usa los usecases, nunca llama directo a `data`).

### Features definidos

| Feature | Responsabilidad |
|---|---|
| `auth` | Login, registro, recuperación de contraseña, selección de rol (pasajero/conductor) |
| `onboarding` | Pantallas de bienvenida previas al login |
| `profile` | Ver/editar perfil, datos del vehículo (conductor), documentos |
| `trip_request` | Pasajero define origen/destino y propone tarifa inicial |
| `negotiation` | Lógica de ofertas/contraofertas/aceptación/rechazo entre pasajero y conductor |
| `trip_tracking` | Seguimiento del viaje en curso (mapa, estado, chat rápido) |
| `trip_history` | Historial de viajes pasados |
| `rating` | Calificación mutua pasajero ↔ conductor al finalizar el viaje |
| `wallet` | Saldo, métodos de pago, historial de transacciones |
| `chat` | Mensajería entre pasajero y conductor durante negociación/viaje |
| `notifications` | Centro de notificaciones in-app |
| `support` | Ayuda, FAQ, contacto con soporte |
| `driver_home` | Pantalla principal del conductor (mapa con solicitudes disponibles) |
| `passenger_home` | Pantalla principal del pasajero (mapa para solicitar viaje) |

---

## 3. Entidades (Domain Layer)

Entidades = objetos de negocio puros, compartidos conceptualmente entre features.

| Entidad | Pertenece a | Descripción |
|---|---|---|
| `User` | auth/profile | Datos base de usuario (id, nombre, rol, teléfono, foto) |
| `DriverProfile` | profile | Datos extendidos del conductor (vehículo, placa, licencia, documentos) |
| `Trip` | trip_request/trip_tracking | Viaje: origen, destino, estado, pasajero, conductor asignado |
| `Offer` | negotiation | Oferta de tarifa: monto, autor (pasajero/conductor), estado (pendiente/aceptada/rechazada/contraoferta) |
| `NegotiationSession` | negotiation | Agrupa el historial de ofertas de un `Trip` específico |
| `Rating` | rating | Calificación: puntaje, comentario, autor, receptor, viaje asociado |
| `WalletTransaction` | wallet | Movimiento de saldo: monto, tipo, fecha, viaje asociado |
| `ChatMessage` | chat | Mensaje: contenido, autor, timestamp, viaje asociado |
| `AppNotification` | notifications | Notificación: título, cuerpo, tipo, leída/no leída |

---

## 4. Casos de uso (Domain Layer) — por feature

Cada caso de uso = una acción de negocio, una clase, un método `call()`.

**auth**
- `LoginUser`, `RegisterUser`, `LogoutUser`, `RecoverPassword`, `SelectUserRole`

**profile**
- `GetUserProfile`, `UpdateUserProfile`, `UploadDriverDocuments`

**trip_request**
- `CreateTripRequest`, `ProposeInitialFare`, `CancelTripRequest`

**negotiation**
- `SendOffer`, `AcceptOffer`, `RejectOffer`, `CounterOffer`, `SelectBestOffer`, `GetNegotiationHistory`

**trip_tracking**
- `GetTripStatus`, `UpdateDriverLocation`, `StartTrip`, `CompleteTrip`

**trip_history**
- `GetTripHistory`, `GetTripDetail`

**rating**
- `SubmitRating`, `GetUserRatings`

**wallet**
- `GetWalletBalance`, `GetTransactionHistory`, `AddFunds`

**chat**
- `SendMessage`, `GetMessages`

**notifications**
- `GetNotifications`, `MarkNotificationAsRead`

---

## 5. Repositorios (contratos Domain + implementación Data)

Por cada feature con persistencia, el `domain/repositories/` define la interfaz y `data/repositories/` la implementa usando `data/datasources/`.

| Repositorio (interfaz) | Implementado en | Usado por casos de uso |
|---|---|---|
| `AuthRepository` | `data/repositories/auth_repository_impl.dart` | Login/Register/Logout |
| `ProfileRepository` | `profile_repository_impl.dart` | Get/UpdateProfile |
| `TripRepository` | `trip_repository_impl.dart` | CreateTrip/GetStatus |
| `NegotiationRepository` | `negotiation_repository_impl.dart` | SendOffer/AcceptOffer/CounterOffer |
| `RatingRepository` | `rating_repository_impl.dart` | SubmitRating |
| `WalletRepository` | `wallet_repository_impl.dart` | GetBalance/AddFunds |
| `ChatRepository` | `chat_repository_impl.dart` | SendMessage/GetMessages |
| `NotificationRepository` | `notification_repository_impl.dart` | GetNotifications |

---

## 6. Providers (Presentation Layer — gestión de estado)

Un provider por feature, conectando UI con los casos de uso del domain. Sugerido: `Provider` o `Riverpod`.

| Provider | Estado que gestiona |
|---|---|
| `AuthProvider` | Sesión actual, estado de login |
| `ProfileProvider` | Datos del perfil cargado |
| `TripRequestProvider` | Origen, destino, tarifa propuesta |
| `NegotiationProvider` | Lista de ofertas activas, oferta seleccionada |
| `TripTrackingProvider` | Estado del viaje en curso, ubicación en tiempo real |
| `TripHistoryProvider` | Lista de viajes pasados |
| `RatingProvider` | Estado del formulario de calificación |
| `WalletProvider` | Saldo, transacciones |
| `ChatProvider` | Mensajes del chat activo |
| `NotificationProvider` | Lista de notificaciones, contador no leídas |
| `DriverHomeProvider` | Solicitudes de viaje disponibles para el conductor |
| `PassengerHomeProvider` | Estado del mapa/búsqueda del pasajero |

---

## 7. Routing (`core/routing/`)

Define las rutas nombradas de la app y el árbol de navegación. Sugerido: `go_router`.

Ejemplo de nombres de ruta (sin implementación todavía):

```
/splash
/onboarding
/login
/register
/role-selection
/passenger/home
/passenger/trip-request
/passenger/negotiation
/passenger/tracking
/driver/home
/driver/incoming-requests
/driver/negotiation
/driver/tracking
/trip/history
/trip/detail/:id
/rating/:tripId
/profile
/profile/edit
/wallet
/chat/:tripId
/notifications
/support
```

---

## 8. Las 22 pantallas del MVP

| # | Pantalla | Feature | Rol |
|---|---|---|---|
| 1 | Splash | onboarding | Ambos |
| 2 | Onboarding / Bienvenida | onboarding | Ambos |
| 3 | Login | auth | Ambos |
| 4 | Registro | auth | Ambos |
| 5 | Recuperar contraseña | auth | Ambos |
| 6 | Selección de rol (Pasajero/Conductor) | auth | Ambos |
| 7 | Home Pasajero (mapa, botón solicitar) | passenger_home | Pasajero |
| 8 | Solicitud de viaje (origen/destino + tarifa inicial) | trip_request | Pasajero |
| 9 | Negociación — vista Pasajero (ofertas recibidas) | negotiation | Pasajero |
| 10 | Selección de mejor oferta | negotiation | Pasajero |
| 11 | Home Conductor (mapa, solicitudes cercanas) | driver_home | Conductor |
| 12 | Detalle de solicitud entrante | driver_home | Conductor |
| 13 | Negociación — vista Conductor (aceptar/contraofertar/rechazar) | negotiation | Conductor |
| 14 | Viaje en curso / Tracking (mapa en vivo) | trip_tracking | Ambos |
| 15 | Chat del viaje | chat | Ambos |
| 16 | Finalización del viaje (resumen) | trip_tracking | Ambos |
| 17 | Calificación post-viaje | rating | Ambos |
| 18 | Historial de viajes | trip_history | Ambos |
| 19 | Detalle de viaje (historial) | trip_history | Ambos |
| 20 | Perfil de usuario | profile | Ambos |
| 21 | Edición de perfil / Documentos del conductor | profile | Ambos |
| 22 | Billetera (saldo y transacciones) | wallet | Ambos |

*(Notificaciones y Soporte quedan como pantallas secundarias fuera del conteo de las 22 principales del flujo MVP, pero ya tienen carpeta reservada en `features/notifications` y `features/support` para etapas posteriores.)*

---

## 9. Clean Architecture en el Backend (Django)

El backend organiza cada dominio de negocio como una "app" Django, dividida internamente en capas para mantener el paralelismo con el frontend.

```
backend/motolink_backend/
├── config/                        → settings.py, urls.py raíz, wsgi/asgi, configuración del proyecto Django
└── apps/
    └── <app>/
        ├── domain/                 → Entidades de negocio puras / reglas de validación (independientes del ORM)
        ├── application/
        │   └── usecases/           → Orquestación de la lógica de negocio (equivalente a los usecases del frontend)
        ├── infrastructure/
        │   ├── migrations/         → Migraciones de modelos Django (ORM ↔ SQLite)
        │   └── serializers/        → Serializers DRF (modelo ↔ JSON)
        └── presentation/           → Views/ViewSets DRF, urls.py de la app (capa HTTP)
```

### Apps definidas

| App | Responsabilidad |
|---|---|
| `users` | Autenticación, perfiles de pasajero y conductor |
| `trips` | Ciclo de vida del viaje (solicitud, asignación, estado, finalización) |
| `negotiation` | Ofertas, contraofertas, aceptación/rechazo de tarifas |
| `ratings` | Calificaciones entre pasajero y conductor |
| `wallet` | Saldo y transacciones |
| `chat` | Mensajería asociada a un viaje |
| `notifications` | Notificaciones push/in-app |
| `core` | Utilidades compartidas entre apps (permisos comunes, mixins, excepciones base) |

### Regla de dependencia (igual que en frontend)

```
presentation (views/DRF)  →  application/usecases  →  domain
                                      ↑
                              infrastructure (ORM, serializers)
```

* `domain` no importa Django ni DRF: son reglas de negocio puras.
* `infrastructure` implementa el acceso a datos (modelos ORM) que `application` usa.
* `presentation` solo expone HTTP; no contiene lógica de negocio.

---

## 10. Próximos pasos (fuera de esta etapa)

1. Inicializar proyecto Flutter real (`flutter create`) dentro de `frontend/motolink_app`.
2. Inicializar proyecto Django real (`django-admin startproject`) dentro de `backend/motolink_backend`.
3. Definir modelos Django concretos por app.
4. Implementar entidades y usecases del frontend.
5. Definir contratos de API (endpoints REST) entre frontend y backend.

> Esta etapa solo entrega la estructura de carpetas y su documentación. No hay código funcional, modelos, ni dependencias instaladas.
