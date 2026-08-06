# Desplegar el backend en Render

Guía para dejar la API accesible desde internet, de modo que la app
instalada en varios teléfonos pueda usarla.

El repositorio ya trae `render.yaml`, así que Render configura el
servicio solo. Solo hay que crear la cuenta y pegar dos secretos.

---

## 1. Antes de empezar

Necesitas:

- El repositorio en GitHub, con la rama `master` al día.
- El JSON de la cuenta de servicio de Firebase, el que está fuera del
  repositorio (`motolink-admin.json`). Ábrelo en un editor: vas a
  necesitar **copiar todo su contenido**.

---

## 2. Crear el servicio

1. Entra en <https://render.com> y regístrate. Lo más cómodo es
   **"Sign in with GitHub"**: así Render ya puede ver tus repositorios.
2. En el panel: **New > Blueprint**.
3. Elige el repositorio `appmotolink`.
4. Render lee `render.yaml` y propone un servicio llamado `motolink-api`.
   Acéptalo.

No hace falta que toques el comando de build ni el de arranque: ya vienen
en el archivo, con los parámetros correctos.

---

## 3. Pegar los dos secretos

Render pedirá las variables marcadas como "sync: false", que son las que
no se versionan por ser sensibles.

### `FIREBASE_CREDENTIALS_JSON`

Abre `motolink-admin.json` y **pega su contenido completo**, desde la
primera `{` hasta la última `}`. No la ruta del archivo: el contenido.

Ese JSON contiene saltos de línea dentro de la clave privada (escritos
como `\n`). Pégalo tal cual, sin reformatear ni quitar nada.

### `DJANGO_CORS_ORIGINS`

Solo importa si además vas a servir la versión web. Para probar únicamente
con el APK, pon el dominio que Render te asigne, por ejemplo:

```
https://motolink-api.onrender.com
```

Las demás variables (`DJANGO_SECRET_KEY`, `DJANGO_DEBUG`,
`FIREBASE_PROJECT_ID`...) las rellena `render.yaml`. La clave secreta la
genera Render sola.

---

## 4. Desplegar y comprobar

El primer despliegue tarda unos minutos. Cuando termine, prueba:

```bash
curl -i https://TU-SERVICIO.onrender.com/api/solicitudes-viaje/
```

Debe responder **403**. Eso es señal de que va bien: la API exige sesión.
Si respondiera 200 con datos, algo está mal configurado.

Para comprobar el camino completo, crea un usuario y entra:

```bash
curl -X POST https://TU-SERVICIO.onrender.com/api/usuarios/ \
  -H "Content-Type: application/json" \
  -d '{"nombre":"Prueba","correo":"prueba@motolink.com","contrasena":"MotoLink2026!","rol":"pasajero"}'
```

---

## 5. Apuntar la app al backend

En `mobile/lib/core/constants/api_constants.dart`, cambia las dos URLs
por la de Render:

```dart
static const String baseUrl = 'https://TU-SERVICIO.onrender.com/api';
static const String socketUrl = 'https://TU-SERVICIO.onrender.com';
```

Y compila el APK:

```bash
cd mobile && flutter build apk --release
```

Queda en `build/app/outputs/flutter-apk/app-release.apk`. Ese archivo es
el que compartes con tu equipo.

---

## 6. Evitar que el servicio se duerma

El plan gratuito de Render suspende el servicio tras unos 15 minutos sin
tráfico, y la siguiente petición tarda cerca de un minuto en responder.
Además, las conexiones de Socket.IO abiertas se cortan.

La forma habitual de evitarlo durante una temporada de pruebas es un
monitor gratuito, por ejemplo UptimeRobot, que pida
`/api/solicitudes-viaje/` cada 10 minutos. Un mes de servicio despierto
son unas 720 horas, dentro de lo que incluye el plan gratuito, pero
conviene que verifiques los límites vigentes: cambian con el tiempo.

---

## Notas

**No hace falta `migrate`.** Todos los datos están en Firestore y las
sesiones se firman en cookie, así que la API funciona sin ninguna base
de datos SQL. Está comprobado apuntando a un SQLite inexistente. Lo único
que dejaría de funcionar es `/admin`, que ya no muestra datos de MotoLink.

**Un solo proceso.** El comando de arranque usa `--workers 1` a
propósito: python-socketio guarda en memoria qué cliente está en qué
sala, y con varios procesos los eventos en tiempo real se pierden de
forma intermitente. Escalar de verdad exigiría añadir Redis.

**Nunca `gevent` ni `eventlet`.** El SDK de Firestore habla gRPC, cuyo
núcleo en C no sobrevive a su monkey patching: el servidor acepta la
conexión TCP y no responde jamás, sin excepción ni traza en el log.
Por eso el worker es `gthread`.

**Si cambia `DJANGO_SECRET_KEY`**, todas las sesiones abiertas se
invalidan y los usuarios tendrán que volver a iniciar sesión.
