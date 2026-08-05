"""
WSGI config for backend project.

It exposes the WSGI callable as a module-level variable named ``application``.
Wraps Django with the Socket.IO server so both are served on the same port:
HTTP/REST goes to Django, and requests to /socket.io/ go to python-socketio.
This means `python manage.py runserver` already serves realtime events
(over long-polling); run via run_realtime.py for true WebSockets.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os

import socketio
from django.conf import settings
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

django_application = get_wsgi_application()

if settings.DEBUG:
    # Servir /static/ en desarrollo. `manage.py runserver` lo hace solo,
    # pero run_realtime.py levanta la app WSGI directamente y sin esto el
    # admin de Django sale sin hojas de estilo (404 en /static/admin/...).
    # En producción los estáticos los sirve el servidor web, no Django.
    from django.contrib.staticfiles.handlers import StaticFilesHandler

    django_application = StaticFilesHandler(django_application)

from core.realtime.server import sio  # noqa: E402  (después de django.setup())

application = socketio.WSGIApp(sio, django_application)
