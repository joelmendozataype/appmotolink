import logging

import socketio

logger = logging.getLogger('motolink.realtime')

# async_mode explícito: 'threading'.
#
# Antes se dejaba autodetectar, y con eventlet instalado python-socketio lo
# elegía siempre. Eso es incompatible con el SDK de Firestore: gRPC no
# sobrevive al monkey patching de eventlet y la primera consulta se cuelga
# para siempre (ver run_realtime.py). La autodetección lo escogía incluso
# sin llamar a monkey_patch(), por el solo hecho de estar instalado.
#
# En modo 'threading' los WebSockets reales los provee simple-websocket
# sobre un servidor WSGI con hilos (Werkzeug en desarrollo, gunicorn
# --worker-class gthread o waitress en producción).
sio = socketio.Server(
    async_mode='threading',
    cors_allowed_origins='*',
    logger=False,
    engineio_logger=False,
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
