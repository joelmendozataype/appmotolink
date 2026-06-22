"""
WSGI config for backend project.

It exposes the WSGI callable as a module-level variable named ``application``.
Wraps Django with the Socket.IO server so both are served on the same port:
HTTP/REST goes to Django, and requests to /socket.io/ go to python-socketio.
This means `python manage.py runserver` already serves realtime events
(over long-polling); run via run_realtime.py (eventlet) for true WebSockets.

For more information on this file, see
https://docs.djangoproject.com/en/5.2/howto/deployment/wsgi/
"""

import os

import socketio
from django.core.wsgi import get_wsgi_application

os.environ.setdefault('DJANGO_SETTINGS_MODULE', 'backend.settings')

django_application = get_wsgi_application()

from core.realtime.server import sio  # noqa: E402  (después de django.setup())

application = socketio.WSGIApp(sio, django_application)
