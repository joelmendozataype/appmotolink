# MOTOLINK

Aplicación móvil para solicitud y negociación de tarifas de mototaxi.

## Stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter / Dart, go_router, Provider, Socket.IO client |
| Backend | Django / DRF, Cloud Firestore (firebase-admin), python-socketio |
| Arquitectura | Clean Architecture (domain / application / infrastructure / presentation) |

## Estructura

```
MOTOLINK/
├── backend/   # API REST + Socket.IO (Django)
├── mobile/    # App Flutter
└── docs/      # Arquitectura y backlog
```

## Cómo correr el proyecto

### Backend

```bash
cd backend
pip install -r requirements.txt
cp .env.example .env   # y completa las variables de Firebase (ver abajo)
python manage.py runserver
```

Configuración por entorno (`backend/.env`, no versionado — ver
`.env.example`): `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`,
`MOTOLINK_DB_BACKEND`, `FIREBASE_PROJECT_ID`, `FIREBASE_CREDENTIALS_FILE`.
**Antes de desplegar a producción**: define `DJANGO_SECRET_KEY` propia,
`DJANGO_DEBUG=False` y `DJANGO_ALLOWED_HOSTS` con tu dominio real.

#### Base de datos: Cloud Firestore

Los datos de MotoLink viven en Firestore, no en SQLite. Para levantar el
backend necesitas una credencial de cuenta de servicio:

1. Consola de Firebase → Configuración del proyecto → **Cuentas de
   servicio** → *Generar nueva clave privada*.
2. Guarda el JSON **fuera del repositorio** (es un secreto real, a
   diferencia de `google-services.json`, que es config de cliente).
3. Apunta `FIREBASE_CREDENTIALS_FILE` a esa ruta en tu `.env`.

Para trabajar sin credencial (demo offline, CI), usa el almacén en
memoria: `MOTOLINK_DB_BACKEND=memory`. Los datos se pierden al reiniciar.

Reglas de seguridad e índices se despliegan con la CLI de Firebase:

```bash
firebase deploy --only firestore:rules,firestore:indexes
```

#### Migrar los datos históricos de SQLite

Si vienes de la versión con SQLite, el `db.sqlite3` anterior se pasa a
Firestore con un comando. Es idempotente y admite simulación:

```bash
cd backend
python manage.py migrar_a_firestore --dry-run   # solo informa, no escribe
python manage.py migrar_a_firestore             # migra de verdad
```

Los hashes de contraseña se copian tal cual, así que nadie tiene que
cambiar su clave.

### Móvil

```bash
cd mobile
flutter pub get
flutter analyze   # debe quedar sin errores antes de compilar/commitear
flutter run
```

### Demo sin un segundo dispositivo conductor (opcional)

```bash
cd backend
python demo_driver_bot.py
```

## Pruebas automatizadas

```bash
cd backend && python manage.py test     # 28 pruebas: negociación, concurrencia/404, login/sesión, calificación, historial
cd mobile && flutter test               # 14 pruebas: parsing de modelos + widget AsyncStateView
```

## Documentación

- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)
- [docs/BACKLOG.md](docs/BACKLOG.md) — funcionalidades postergadas fuera del MVP
- [docs/VERIFICACION_EJECUCION.md](docs/VERIFICACION_EJECUCION.md) — flujo verificado en ejecución contra el emulador, bugs reales encontrados y corregidos
