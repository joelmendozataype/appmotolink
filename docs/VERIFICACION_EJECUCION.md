# Verificación en ejecución

Este documento responde al pendiente señalado en la reevaluación técnica
("no se ejecutó la app contra el backend; conviene una corrida real").
Registra la verificación end-to-end realizada contra un emulador Android
real y el backend Django corriendo con WebSockets reales (no long-polling).

## Entorno de prueba

- **Emulador**: Pixel 9, Android 14 (API 36), AVD `Pixel_9`
- **Backend**: `python run_realtime.py` (Django + python-socketio sobre
  eventlet, WebSocket real vía `Sec-WebSocket-Accept`, no long-polling)
- **Host visto desde el emulador**: `10.0.2.2:8000` (alias estándar de
  Android Studio hacia `127.0.0.1` de la máquina host)

## Flujo verificado de punta a punta

1. **Registro y login real** — se crearon usuarios reales en la base de
   datos (`pasajero@motolink.com`, `conductor@motolink.com`,
   `admin@motolink.com`) y se autenticó cada rol desde la app, confirmando
   sesión persistida vía `AuthProvider` y cookie de sesión Django.
2. **Solicitud de viaje con GPS** — pantalla "Crear solicitud" capturando
   ubicación real vía `geolocator`.
3. **Negociación en tiempo real entre dos sesiones** — con el pasajero en
   la pantalla de inicio (no en "Ofertas recibidas") y el conductor
   aceptando/contraofertando desde otra sesión, se confirmó:
   - El conductor recibe el evento `SolicitudCreada` al instante, incluso
     parado en su propia pantalla de inicio.
   - El pasajero recibe `OfertaCreada` / `ContraOfertaCreada` al instante,
     incluso parado en su pantalla de inicio (no solo dentro de "Ofertas
     recibidas").
4. **Selección de oferta → viaje asignado** — `seleccionar` crea el
   `Viaje` real en backend y notifica a ambas partes por Socket.IO.
5. **Finalizar viaje → calificación → historial** — el viaje pasa a
   `finalizado`, la calificación se persiste (`Calificacion` 1-5,
   `OneToOneField` con el viaje) y aparece en `/api/historial/` tanto para
   el pasajero como para el conductor.
6. **Panel de administrador** — dashboard con conteos reales
   (pasajeros/mototaxistas/viajes/usuarios) y gestión de usuarios
   (listar/eliminar) contra el backend.

## Bugs reales encontrados y corregidos durante esta verificación

Ejecutar la app contra el backend real —en lugar de solo revisar el
código— sacó a la luz seis problemas que una revisión estática no detecta:

| # | Síntoma observado | Causa | Fix |
|---|---|---|---|
| 1 | Login fallaba con "Correo o contraseña incorrectos" (mensaje engañoso) | `ALLOWED_HOSTS = []` rechazaba el host `10.0.2.2` del emulador con `DisallowedHost` (HTTP 400) | `ALLOWED_HOSTS = ['127.0.0.1', 'localhost', '10.0.2.2']` |
| 2 | La app se congelaba ~340s al enviar una solicitud | `async_mode='threading'` forzado en el `socketio.Server` rompía el upgrade de WebSocket bajo eventlet (`AssertionError: write() before start_response()`), bloqueando el único hilo del servidor | Quitar el `async_mode` forzado; se autodetecta `eventlet` |
| 3 | "Solicitudes disponibles" giraba para siempre | DRF serializa `DecimalField` como string (`"9.00"`); el cliente Dart hacía `(json['tarifa'] as num)`, que lanzaba una excepción nunca capturada | `COERCE_DECIMAL_TO_STRING: False` en `REST_FRAMEWORK` (global, afecta todos los campos decimales) |
| 4 | Tocar "Aceptar/Contraofertar/Rechazar" no hacía nada visible | El backend devolvía `409` correctamente (oferta duplicada), pero la pantalla no tenía `catch`, así que la excepción se perdía en silencio | `try/catch` + `mensajeDeError()` + `ErrorRetryView` aplicado de forma sistemática en las 16 pantallas que llamaban al backend |
| 5 | Dashboard de admin / "Lista de pasajeros" nunca cargaban | `GET /api/usuarios/pasajeros/` no existía en el backend (404) | Se agregó la acción `pasajeros` en `UsuarioViewSet` |
| 6 | El pasajero/conductor no se enteraba de nada si no estaba parado en la pantalla exacta de negociación | Los eventos `OfertaCreada`/`ContraOfertaCreada`/`SolicitudCreada` solo se emitían a la sala de la solicitud o de "conductores"; nadie escuchaba esas salas desde las pantallas de inicio | Las pantallas de inicio (pasajero y conductor) ahora se suscriben a su canal personal/global y muestran un `SnackBar` con acción "Ver" |

Todos estos fixes están en el historial de commits del repositorio, con
mensajes que describen el síntoma observado y la causa — no son cambios
especulativos.

## Pruebas automatizadas agregadas

En respuesta al pendiente "agregar al menos pruebas del flujo de
negociación":

- **Backend** (`python manage.py test`): 23 pruebas — flujo completo de
  negociación (aceptar/contraofertar/rechazar/seleccionar/finalizar/
  calificar/historial), duplicidad de ofertas, validación de rango de
  calificación, historial visible para ambas partes, login/registro,
  persistencia de sesión (`/me`, logout), y casos de concurrencia entre
  conductores compitiendo por la misma solicitud.
- **Mobile** (`flutter test`): 14 pruebas — parsing de modelos contra la
  forma real del JSON del backend (snake_case, decimales como `num`,
  contraseña ausente) y pruebas de widget del componente `AsyncStateView`
  compartido (cargando/error/vacío/datos, callback de reintentar).

Ambas suites pasan en verde (`OK` / `All tests passed!`) al momento de
este commit.

### Bug adicional encontrado por las pruebas nuevas

Al escribir `negotiation/tests_concurrencia.py` se confirmó que
`seleccionar` una oferta con un UUID inexistente lanzaba `500` (el
repositorio usa `Oferta.objects.get()`, que levanta `DoesNotExist` sin
capturar). Se corrigió devolviendo `404` controlado en `seleccionar`,
`aceptar`, `contraofertar` y `rechazar` — los cuatro endpoints tenían el
mismo patrón de bug.

## Herramienta de demo (no parte del MVP)

`backend/demo_driver_bot.py` simula a un conductor real conectado por
Socket.IO/REST para no depender de un segundo dispositivo en una
demostración en vivo. No reemplaza la negociación real: usa los mismos
endpoints que usaría la app de un conductor humano. Ver su docstring.
