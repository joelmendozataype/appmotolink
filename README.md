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

### Demo sin un segundo dispositivo conductor (opcional)

```bash
cd backend
python demo_driver_bot.py
```

## Pruebas automatizadas

```bash
cd backend && python manage.py test     # 16 pruebas: flujo de negociación, login, calificación, historial
cd mobile && flutter test               # 9 pruebas: parsing de modelos contra el contrato real del backend
```

## Documentación

- [docs/ARQUITECTURA.md](docs/ARQUITECTURA.md)
- [docs/BACKLOG.md](docs/BACKLOG.md) — funcionalidades postergadas fuera del MVP
- [docs/VERIFICACION_EJECUCION.md](docs/VERIFICACION_EJECUCION.md) — flujo verificado en ejecución contra el emulador, bugs reales encontrados y corregidos
