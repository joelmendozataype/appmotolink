import logging

import socketio

logger = logging.getLogger('motolink.realtime')

# 'threading' funciona tanto con manage.py runserver (long-polling) como
# bajo eventlet ya parcheado (run_realtime.py): eventlet.monkey_patch()
# vuelve verdes los hilos de Python, así que 'threading' obtiene
# WebSockets reales en ese caso sin tener que detectarlo automáticamente.
sio = socketio.Server(
    cors_allowed_origins='*', logger=False, engineio_logger=False, async_mode='threading',
)


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
