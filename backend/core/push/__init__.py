"""Notificaciones push (Firebase Cloud Messaging).

Socket.IO solo llega a quien tiene la app abierta. Un mototaxista con el
teléfono en el bolsillo no se entera de una solicitud nueva, que es justo
cuando más falta hace. Estas notificaciones cubren ese hueco.

Aquí por fin se usa el `google-services.json` que estaba en el proyecto
sin función desde el principio.
"""
from core.push.dispositivos import (
    DispositivoRepository,
    FirestoreDispositivoRepository,
)
from core.push.sender import PushSender, FirebasePushSender, PushSilencioso

__all__ = [
    'DispositivoRepository',
    'FirestoreDispositivoRepository',
    'PushSender',
    'FirebasePushSender',
    'PushSilencioso',
]
