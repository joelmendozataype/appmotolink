"""Envío de notificaciones push.

Se aísla en un puerto para que los tests corran sin tocar Firebase y para
que un fallo de FCM no tumbe una operación de negocio: si el envío falla,
el viaje ya se creó igual.
"""
import logging
from abc import ABC, abstractmethod

logger = logging.getLogger('motolink.push')


class PushSender(ABC):
    @abstractmethod
    def enviar(self, tokens, titulo, cuerpo, datos=None):
        """Devuelve la lista de tokens que ya no son válidos."""


class PushSilencioso(PushSender):
    """No envía nada. Es el que se usa en tests y en desarrollo, donde no
    interesa gastar cuota ni depender de la red."""

    def __init__(self):
        self.enviados = []

    def enviar(self, tokens, titulo, cuerpo, datos=None):
        self.enviados.append({
            'tokens': list(tokens), 'titulo': titulo,
            'cuerpo': cuerpo, 'datos': datos or {},
        })
        return []


class FirebasePushSender(PushSender):
    def enviar(self, tokens, titulo, cuerpo, datos=None):
        tokens = [t for t in tokens if t]
        if not tokens:
            return []

        from firebase_admin import messaging

        from core.firestore.firebase_store import _inicializar_app, ejecutar

        _inicializar_app()

        mensaje = messaging.MulticastMessage(
            tokens=tokens,
            notification=messaging.Notification(title=titulo, body=cuerpo),
            # Los datos viajan como texto: FCM no admite otro tipo, y la
            # app los usa para saber a qué pantalla llevar al usuario.
            data={k: str(v) for k, v in (datos or {}).items()},
            android=messaging.AndroidConfig(priority='high'),
        )

        try:
            # Igual que las lecturas de Firestore: el SDK usa gRPC y hay
            # que sacarlo del hub si el servidor corriera con eventlet.
            respuesta = ejecutar(messaging.send_each_for_multicast, mensaje)
        except Exception as error:
            # Una notificación que no sale no debe romper la operación que
            # la disparó: el viaje ya está creado, el aviso es accesorio.
            logger.warning('No se pudo enviar la notificación push: %s', error)
            return []

        return self._tokens_caducados(tokens, respuesta)

    @staticmethod
    def _tokens_caducados(tokens, respuesta):
        """Tokens que Firebase rechaza por no existir ya.

        Ocurre cuando el usuario desinstala la app. Conviene borrarlos: si
        no, la lista crece indefinidamente y cada envío desperdicia
        intentos contra destinos muertos.
        """
        from firebase_admin import messaging

        caducados = []
        for token, resultado in zip(tokens, respuesta.responses):
            if resultado.success:
                continue
            if isinstance(
                resultado.exception,
                (messaging.UnregisteredError, ValueError),
            ):
                caducados.append(token)
        return caducados
