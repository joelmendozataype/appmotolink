"""Registro de dispositivos para notificaciones push.

Cada instalación de la app tiene un token de FCM. Un usuario puede tener
varios —teléfono y tablet, o el mismo teléfono tras reinstalar—, así que
se guardan como documentos independientes en vez de un campo del usuario.

El id del documento es el propio token: así registrarlo dos veces no
duplica nada, y cuando Firebase avisa de que un token caducó se borra
directamente por su id.
"""
from abc import ABC, abstractmethod

from core.firestore import Filtro, get_store
from core.firestore.campos import a_texto_id, ahora

DISPOSITIVOS = 'dispositivos'


class DispositivoRepository(ABC):
    @abstractmethod
    def registrar(self, usuario_id, token):
        ...

    @abstractmethod
    def tokens_de(self, usuario_id):
        ...

    @abstractmethod
    def tokens_de_varios(self, usuario_ids):
        ...

    @abstractmethod
    def eliminar(self, token):
        ...


class FirestoreDispositivoRepository(DispositivoRepository):
    def __init__(self, store=None):
        self._store_inyectado = store

    @property
    def store(self):
        return self._store_inyectado or get_store()

    def registrar(self, usuario_id, token):
        """Asocia el token al usuario.

        Se usa `set` y no `create` a propósito: si el mismo teléfono lo
        usa otra persona —algo normal en un aparato compartido—, el token
        debe pasar a apuntar a la cuenta nueva, no quedarse en la vieja
        mandándole notificaciones ajenas.
        """
        self.store.set(DISPOSITIVOS, token, {
            'usuario_id': a_texto_id(usuario_id),
            'registrado_en': ahora(),
        })

    def tokens_de(self, usuario_id):
        filtros = [Filtro('usuario_id', '==', a_texto_id(usuario_id))]
        return [token for token, _ in self.store.query(DISPOSITIVOS, filtros)]

    def tokens_de_varios(self, usuario_ids):
        """Los tokens de un grupo, en una sola consulta por usuario.

        Se usa al avisar a todos los mototaxistas de una solicitud nueva.
        """
        ids = {a_texto_id(i) for i in usuario_ids if i}
        if not ids:
            return []
        return [
            token
            for token, datos in self.store.query(DISPOSITIVOS)
            if datos.get('usuario_id') in ids
        ]

    def eliminar(self, token):
        self.store.delete(DISPOSITIVOS, token)
