"""Levanta Django + Socket.IO en un solo proceso con soporte real de
WebSockets (vía eventlet). Uso:

    python run_realtime.py

Para desarrollo sin necesidad de WebSockets reales (solo long-polling),
basta con `python manage.py runserver`, ya que backend/wsgi.py también
envuelve el servidor Socket.IO.
"""

import eventlet
import eventlet.wsgi

eventlet.monkey_patch()

import os  # noqa: E402

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

import django  # noqa: E402

django.setup()

from backend.wsgi import application  # noqa: E402

if __name__ == '__main__':
    print('MOTOLINK realtime server escuchando en http://0.0.0.0:8000 (Socket.IO + Django)')
    eventlet.wsgi.server(eventlet.listen(('0.0.0.0', 8000)), application)
