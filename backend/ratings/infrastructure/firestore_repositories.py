"""Repositorio de calificaciones sobre Firestore.

La relación 1:1 con el viaje (OneToOneField en SQLite) se reconstruye con
una colección índice `calificaciones_por_viaje`, cuyo id de documento es
el id del viaje: reservarlo es un `create()` que falla si ya existe.
"""
from core.firestore import DocumentoYaExisteError, Filtro, get_store
from core.firestore.campos import a_datetime, a_texto_id, ahora
from core.firestore.colecciones import CALIFICACIONES
from ratings.domain.entities import Calificacion
from ratings.domain.repositories import (
    CalificacionNoEncontradaError,
    CalificacionRepository,
    ViajeYaCalificadoError,
)

INDICE_POR_VIAJE = 'calificaciones_por_viaje'


class FirestoreCalificacionRepository(CalificacionRepository):
    def __init__(self, store=None):
        self._store_inyectado = store

    @property
    def store(self):
        return self._store_inyectado or get_store()

    @staticmethod
    def _a_documento(calificacion):
        return {
            'viaje_id': a_texto_id(calificacion.viaje_id),
            'puntuacion': int(calificacion.puntuacion),
            'comentario': calificacion.comentario or '',
            'fecha': calificacion.fecha,
        }

    @staticmethod
    def _a_entidad(doc_id, datos):
        return Calificacion(
            id=a_texto_id(doc_id),
            viaje_id=datos.get('viaje_id'),
            puntuacion=datos.get('puntuacion', 1),
            comentario=datos.get('comentario', ''),
            fecha=a_datetime(datos.get('fecha')),
        )

    def crear(self, calificacion):
        if calificacion.fecha is None:
            calificacion.fecha = ahora()

        viaje_id = a_texto_id(calificacion.viaje_id)
        try:
            self.store.create(
                INDICE_POR_VIAJE, viaje_id, {'calificacion_id': calificacion.id},
            )
        except DocumentoYaExisteError as error:
            raise ViajeYaCalificadoError(viaje_id) from error

        try:
            self.store.set(
                CALIFICACIONES, calificacion.id, self._a_documento(calificacion),
            )
        except Exception:
            self.store.delete(INDICE_POR_VIAJE, viaje_id)
            raise
        return calificacion

    def obtener_por_id(self, calificacion_id):
        calificacion_id = a_texto_id(calificacion_id)
        datos = self.store.get(CALIFICACIONES, calificacion_id)
        if datos is None:
            raise CalificacionNoEncontradaError(calificacion_id)
        return self._a_entidad(calificacion_id, datos)

    def buscar_por_viaje(self, viaje_id):
        indice = self.store.get(INDICE_POR_VIAJE, a_texto_id(viaje_id))
        if indice is None:
            return None
        try:
            return self.obtener_por_id(indice['calificacion_id'])
        except CalificacionNoEncontradaError:
            return None

    def listar(self, *, viaje_id=None):
        filtros = [Filtro('viaje_id', '==', a_texto_id(viaje_id))] if viaje_id else []
        return [
            self._a_entidad(doc_id, datos)
            for doc_id, datos in self.store.query(CALIFICACIONES, filtros)
        ]
