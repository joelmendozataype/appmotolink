import logging

import socketio

logger = logging.getLogger('motolink.realtime')

# Sin async_mode explícito: python-socketio autodetecta el modo correcto.
# Bajo manage.py runserver usa 'threading' (long-polling); bajo run_realtime.py
# (que llama eventlet.monkey_patch() antes de importar este módulo) detecta
# eventlet ya cargado y usa 'eventlet', que sabe hacer el upgrade real de
# WebSocket vía el hijacking de sockets de eventlet. Forzar 'threading' rompe
# ese upgrade bajo eventlet (AssertionError: write() before start_response()).
sio = socketio.Server(cors_allowed_origins='*', logger=False, engineio_logger=False)


@sio.event
def connect(sid, environ, auth):
    logger.info('Cliente conectado: %s', sid)


@sio.event
def disconnect(sid):
    logger.info('Cliente desconectado: %s', sid)


@sio.event
def join_room(sid, data):
    """El cliente se suscribe a un canal: 'conductores', 'solicitud_<id>' o 'usuario_<id>'."""
    room = data.get('room')
    if room:
        sio.enter_room(sid, room)
        sio.emit('room_joined', {'room': room}, room=sid)


@sio.event
def leave_room(sid, data):
    room = data.get('room')
    if room:
        sio.leave_room(sid, room)
