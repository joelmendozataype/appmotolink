"""Levanta Django + Socket.IO en un solo proceso con soporte real de
WebSockets. Uso:

    python run_realtime.py

Para desarrollo sin WebSockets reales (solo long-polling) basta con
`python manage.py runserver`, ya que backend/wsgi.py también envuelve el
servidor Socket.IO.

Por qué ya no se usa eventlet
-----------------------------
Hasta la migración a Firestore, este script llamaba a
`eventlet.monkey_patch()`. Eso es incompatible con el SDK de Firestore:
habla gRPC, cuyo núcleo está escrito en C y maneja sus propios sockets e
hilos. Con eventlet monkey-patcheado, la primera consulta a Firestore no
retorna nunca — el servidor acepta la conexión TCP y se queda mudo.
Sacarla a un hilo con `eventlet.tpool` tampoco alcanza; el bloqueo se
produce igual.

La alternativa es el modo 'threading' de python-socketio sobre el
servidor de desarrollo de Werkzeug, que da WebSockets reales a través de
`simple-websocket` sin parchear nada. gRPC queda contento y el tiempo
real sigue funcionando.

Para producción, un servidor WSGI con hilos (gunicorn con
`--worker-class gthread`, waitress, uWSGI) sirve el mismo `application`.
"""

import os

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

import django  # noqa: E402

django.setup()

from werkzeug.serving import run_simple  # noqa: E402

from backend.wsgi import application  # noqa: E402

if __name__ == '__main__':
    print('MOTOLINK realtime server escuchando en http://0.0.0.0:8000 (Socket.IO + Django)')
    run_simple(
        '0.0.0.0', 8000, application,
        threaded=True,          # un hilo por petición: las llamadas a Firestore no se bloquean entre sí
        use_reloader=False,     # el reloader duplicaría el proceso y el cliente de Firestore
        use_debugger=False,
    )
