# MOTOLINK

Aplicación móvil para solicitud y negociación de tarifas de mototaxi.

## Stack

| Capa | Tecnología |
|---|---|
| Frontend | Flutter / Dart, go_router, Provider, Socket.IO client |
| Backend | Django / DRF, SQLite, python-socketio |
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
cp .env.example .env   # opcional en desarrollo; sin .env se usan defaults seguros
python manage.py migrate
python manage.py runserver
```

Configuración por entorno (`backend/.env`, no versionado — ver
`.env.example`): `DJANGO_SECRET_KEY`, `DJANGO_DEBUG`, `DJANGO_ALLOWED_HOSTS`.
**Antes de desplegar a producción**: define `DJANGO_SECRET_KEY` propia,
`DJANGO_DEBUG=False` y `DJANGO_ALLOWED_HOSTS` con tu dominio real.

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
cd backend && python manage.py test     # 23 pruebas: negociación, concurrencia/404, login/sesión, calificación, historial
cd mobile && flutter test               # 14 pruebas: parsing de modelos + widget AsyncStateView
```

## Documentación

- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)
- [docs/BACKLOG.md](docs/BACKLOG.md) — funcionalidades postergadas fuera del MVP
- [docs/VERIFICACION_EJECUCION.md](docs/VERIFICACION_EJECUCION.md) — flujo verificado en ejecución contra el emulador, bugs reales encontrados y corregidos
