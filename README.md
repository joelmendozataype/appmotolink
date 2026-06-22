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
python manage.py migrate
python manage.py runserver
```

### Móvil

```bash
cd mobile
flutter pub get
flutter run
```

## Documentación

- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)
- [docs/BACKLOG.md](docs/BACKLOG.md) — funcionalidades postergadas fuera del MVP
