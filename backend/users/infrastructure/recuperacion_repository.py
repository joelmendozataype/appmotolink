"""Almacenamiento de los códigos de recuperación.

El id del documento es el correo en minúsculas, no el del usuario: así
pedir un código nuevo sobrescribe el anterior sin dejar varios vivos a la
vez, y se puede buscar sin haber resuelto todavía a qué cuenta pertenece.
"""
from core.firestore import get_store
from core.firestore.campos import a_datetime
from users.domain.recuperacion import CodigoRecuperacion

RECUPERACIONES = 'recuperaciones'


def _clave(correo):
    return correo.strip().lower()


class RecuperacionRepository:
    def __init__(self, store=None):
        self._store_inyectado = store

    @property
    def store(self):
        return self._store_inyectado or get_store()

    def guardar(self, correo, codigo):
        self.store.set(RECUPERACIONES, _clave(correo), {
            'usuario_id': codigo.usuario_id,
            'codigo_hash': codigo.codigo_hash,
            'expira_en': codigo.expira_en,
            'intentos': codigo.intentos,
        })

    def buscar(self, correo):
        datos = self.store.get(RECUPERACIONES, _clave(correo))
        if datos is None:
            return None
        return CodigoRecuperacion(
            usuario_id=datos['usuario_id'],
            codigo_hash=datos['codigo_hash'],
            expira_en=a_datetime(datos['expira_en']),
            intentos=datos.get('intentos', 0),
        )

    def registrar_intento_fallido(self, correo, codigo):
        codigo.intentos += 1
        self.guardar(correo, codigo)

    def eliminar(self, correo):
        self.store.delete(RECUPERACIONES, _clave(correo))
