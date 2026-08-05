"""Repositorios de usuarios sobre Firestore.

Firestore no tiene índices UNIQUE. La unicidad de correo —que en SQLite
daba la columna `correo UNIQUE`— se reconstruye con una colección índice
`correos_usuario`, donde el id del documento ES el correo. Reservar el
correo es entonces un `create()`, que falla si ya está tomado.
"""
from core.firestore import DocumentoYaExisteError, Filtro, get_store
from core.firestore.campos import a_texto_id
from core.firestore.colecciones import MOTOTAXISTAS, USUARIOS
from users.domain.entities import Mototaxista, Usuario
from users.domain.repositories import (
    CorreoDuplicadoError,
    MototaxistaNoEncontradoError,
    MototaxistaRepository,
    UsuarioNoEncontradoError,
    UsuarioRepository,
)

CORREOS = 'correos_usuario'


def _clave_correo(correo):
    return correo.strip().lower()


def _a_documento(usuario):
    return {
        'nombre': usuario.nombre,
        'correo': usuario.correo,
        'contrasena': usuario.contrasena,
        'rol': str(usuario.rol),
        'is_active': bool(usuario.is_active),
    }


def _a_entidad(doc_id, datos):
    return Usuario(
        id=a_texto_id(doc_id),
        nombre=datos.get('nombre', ''),
        correo=datos.get('correo', ''),
        contrasena=datos.get('contrasena', ''),
        rol=datos.get('rol', ''),
        is_active=datos.get('is_active', True),
    )


class FirestoreUsuarioRepository(UsuarioRepository):
    def __init__(self, store=None):
        self._store_inyectado = store

    @property
    def store(self):
        return self._store_inyectado or get_store()

    def _reservar_correo(self, correo, usuario_id):
        try:
            self.store.create(CORREOS, _clave_correo(correo), {'usuario_id': usuario_id})
        except DocumentoYaExisteError as error:
            raise CorreoDuplicadoError(correo) from error

    def _liberar_correo(self, correo):
        if correo:
            self.store.delete(CORREOS, _clave_correo(correo))

    def crear(self, usuario):
        self._reservar_correo(usuario.correo, usuario.id)
        try:
            self.store.set(USUARIOS, usuario.id, _a_documento(usuario))
        except Exception:
            # No dejar el correo reservado si el alta falló a medias.
            self._liberar_correo(usuario.correo)
            raise
        return usuario

    def obtener_por_id(self, usuario_id):
        datos = self.store.get(USUARIOS, a_texto_id(usuario_id))
        if datos is None:
            raise UsuarioNoEncontradoError(usuario_id)
        return _a_entidad(usuario_id, datos)

    def buscar_por_correo(self, correo):
        indice = self.store.get(CORREOS, _clave_correo(correo))
        if indice is None:
            return None
        try:
            return self.obtener_por_id(indice['usuario_id'])
        except UsuarioNoEncontradoError:
            return None

    def listar(self, *, rol=None):
        filtros = [Filtro('rol', '==', str(rol))] if rol else []
        return [
            _a_entidad(doc_id, datos)
            for doc_id, datos in self.store.query(USUARIOS, filtros)
        ]

    def guardar(self, usuario):
        anterior = self.store.get(USUARIOS, usuario.id)
        if anterior is None:
            raise UsuarioNoEncontradoError(usuario.id)

        correo_anterior = anterior.get('correo', '')
        if _clave_correo(correo_anterior) != _clave_correo(usuario.correo):
            self._reservar_correo(usuario.correo, usuario.id)
            self._liberar_correo(correo_anterior)

        self.store.set(USUARIOS, usuario.id, _a_documento(usuario))
        return usuario

    def eliminar(self, usuario_id):
        usuario_id = a_texto_id(usuario_id)
        datos = self.store.get(USUARIOS, usuario_id)
        if datos is None:
            raise UsuarioNoEncontradoError(usuario_id)
        self._liberar_correo(datos.get('correo', ''))
        self.store.delete(USUARIOS, usuario_id)
        # El mototaxista compartía PK con el usuario (ON DELETE CASCADE).
        self.store.delete(MOTOTAXISTAS, usuario_id)


class FirestoreMototaxistaRepository(MototaxistaRepository):
    def __init__(self, store=None, usuario_repo=None):
        self._store_inyectado = store
        self.usuario_repo = usuario_repo or FirestoreUsuarioRepository(store)

    @property
    def store(self):
        return self._store_inyectado or get_store()

    def _a_entidad(self, doc_id, datos, *, con_usuario=True):
        mototaxista = Mototaxista(
            usuario_id=a_texto_id(doc_id),
            licencia=datos.get('licencia', ''),
            placa=datos.get('placa', ''),
            marca_vehiculo=datos.get('marca_vehiculo', ''),
            modelo_vehiculo=datos.get('modelo_vehiculo', ''),
        )
        if con_usuario:
            # Equivalente al select_related('usuario') del ORM.
            try:
                mototaxista.usuario = self.usuario_repo.obtener_por_id(doc_id)
            except UsuarioNoEncontradoError:
                mototaxista.usuario = None
        return mototaxista

    @staticmethod
    def _a_documento(mototaxista):
        return {
            'licencia': mototaxista.licencia,
            'placa': mototaxista.placa,
            'marca_vehiculo': mototaxista.marca_vehiculo,
            'modelo_vehiculo': mototaxista.modelo_vehiculo,
        }

    def crear(self, mototaxista):
        self.store.set(
            MOTOTAXISTAS, mototaxista.usuario_id, self._a_documento(mototaxista),
        )
        return mototaxista

    def obtener_por_id(self, usuario_id):
        usuario_id = a_texto_id(usuario_id)
        datos = self.store.get(MOTOTAXISTAS, usuario_id)
        if datos is None:
            raise MototaxistaNoEncontradoError(usuario_id)
        return self._a_entidad(usuario_id, datos)

    def listar(self):
        return [
            self._a_entidad(doc_id, datos)
            for doc_id, datos in self.store.query(MOTOTAXISTAS)
        ]

    def guardar(self, mototaxista):
        return self.crear(mototaxista)

    def eliminar(self, usuario_id):
        usuario_id = a_texto_id(usuario_id)
        if self.store.get(MOTOTAXISTAS, usuario_id) is None:
            raise MototaxistaNoEncontradoError(usuario_id)
        self.store.delete(MOTOTAXISTAS, usuario_id)
