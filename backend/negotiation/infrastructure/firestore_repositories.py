"""Repositorio de ofertas sobre Firestore.

Dos garantías que antes daba SQLite y aquí se reconstruyen:

* UNIQUE(solicitud, conductor) -> id de documento determinista, de modo
  que el segundo intento del mismo conductor choca contra `create()`.
* Transacción al aceptar una oferta -> `compare_and_set` sobre `estado`.
"""
from core.firestore import DocumentoYaExisteError, Filtro, get_store
from core.firestore.campos import a_decimal, a_float, a_texto_id, ahora, a_datetime
from core.firestore.colecciones import OFERTAS
from negotiation.domain.entities import EstadoOferta, Oferta, id_documento
from negotiation.domain.exceptions import OfertaDuplicadaError
from negotiation.domain.repositories import OfertaNoEncontradaError, OfertaRepository
from trips.domain.repositories import SolicitudNoEncontradaError
from trips.infrastructure.firestore_repositories import (
    FirestoreSolicitudViajeRepository,
)
from users.domain.repositories import MototaxistaNoEncontradoError
from users.infrastructure.firestore_repositories import FirestoreMototaxistaRepository


class FirestoreOfertaRepository(OfertaRepository):
    def __init__(self, store=None, mototaxista_repo=None, solicitud_repo=None):
        self._store_inyectado = store
        self.mototaxista_repo = mototaxista_repo or FirestoreMototaxistaRepository(store)
        self.solicitud_repo = solicitud_repo or FirestoreSolicitudViajeRepository(store)

    @property
    def store(self):
        return self._store_inyectado or get_store()

    @staticmethod
    def _a_documento(oferta):
        return {
            'solicitud_id': a_texto_id(oferta.solicitud_id),
            'conductor_id': a_texto_id(oferta.conductor_id),
            'tarifa': a_float(oferta.tarifa),
            'tipo': str(oferta.tipo),
            'estado': str(oferta.estado),
            'fecha': oferta.fecha,
        }

    def _a_entidad(self, doc_id, datos, *, hidratar=True):
        oferta = Oferta(
            id=a_texto_id(doc_id),
            solicitud_id=datos.get('solicitud_id'),
            conductor_id=datos.get('conductor_id'),
            tarifa=a_decimal(datos.get('tarifa')),
            tipo=datos.get('tipo', ''),
            estado=datos.get('estado', EstadoOferta.PENDIENTE),
            fecha=a_datetime(datos.get('fecha')),
        )
        if hidratar:
            # OfertaSerializer anida el conductor completo, y el notifier
            # lee oferta.conductor.usuario.nombre y oferta.solicitud.pasajero_id.
            try:
                oferta.conductor = self.mototaxista_repo.obtener_por_id(
                    oferta.conductor_id,
                )
            except MototaxistaNoEncontradoError:
                oferta.conductor = None
            try:
                oferta.solicitud = self.solicitud_repo.obtener_por_id(
                    oferta.solicitud_id,
                )
            except SolicitudNoEncontradaError:
                oferta.solicitud = None
        return oferta

    def crear(self, *, solicitud, conductor, tarifa, tipo):
        solicitud_id = a_texto_id(getattr(solicitud, 'id', solicitud))
        conductor_id = a_texto_id(getattr(conductor, 'usuario_id', conductor))

        oferta = Oferta(
            id=id_documento(solicitud_id, conductor_id),
            solicitud_id=solicitud_id,
            conductor_id=conductor_id,
            tarifa=a_decimal(tarifa),
            tipo=tipo,
            estado=EstadoOferta.PENDIENTE,
            fecha=ahora(),
        )
        try:
            self.store.create(OFERTAS, oferta.id, self._a_documento(oferta))
        except DocumentoYaExisteError as error:
            # Cierra la ventana de carrera que el chequeo previo del caso
            # de uso no puede cubrir por sí solo.
            raise OfertaDuplicadaError(oferta.id) from error

        oferta.solicitud = solicitud if hasattr(solicitud, 'origen') else None
        oferta.conductor = conductor if hasattr(conductor, 'placa') else None
        return oferta

    def obtener_por_id(self, oferta_id):
        oferta_id = a_texto_id(oferta_id)
        datos = self.store.get(OFERTAS, oferta_id)
        if datos is None:
            raise OfertaNoEncontradaError(oferta_id)
        return self._a_entidad(oferta_id, datos)

    def listar_por_solicitud(self, solicitud_id, *, solo_pendientes=True):
        filtros = [Filtro('solicitud_id', '==', a_texto_id(solicitud_id))]
        if solo_pendientes:
            filtros.append(Filtro('estado', '==', str(EstadoOferta.PENDIENTE)))
        return [
            self._a_entidad(doc_id, datos)
            for doc_id, datos in self.store.query(OFERTAS, filtros)
        ]

    def listar_pendientes(self):
        filtros = [Filtro('estado', '==', str(EstadoOferta.PENDIENTE))]
        return [
            self._a_entidad(doc_id, datos)
            for doc_id, datos in self.store.query(OFERTAS, filtros)
        ]

    def buscar_de_conductor(self, solicitud_id, conductor_id):
        # Con el id determinista esto es una lectura directa, no una query.
        doc_id = id_documento(a_texto_id(solicitud_id), a_texto_id(conductor_id))
        datos = self.store.get(OFERTAS, doc_id)
        if datos is None:
            return None
        return self._a_entidad(doc_id, datos, hidratar=False)

    def guardar(self, oferta):
        self.store.set(OFERTAS, oferta.id, self._a_documento(oferta))
        return oferta

    def aceptar_si_pendiente(self, oferta_id):
        return self.store.compare_and_set(
            OFERTAS,
            a_texto_id(oferta_id),
            'estado',
            str(EstadoOferta.PENDIENTE),
            {'estado': str(EstadoOferta.ACEPTADA)},
        )

    def rechazar_otras(self, solicitud_id, oferta_ganadora_id):
        filtros = [Filtro('solicitud_id', '==', a_texto_id(solicitud_id))]
        for doc_id, datos in self.store.query(OFERTAS, filtros):
            if doc_id == a_texto_id(oferta_ganadora_id):
                continue
            if datos.get('estado') == str(EstadoOferta.RECHAZADA):
                continue
            self.store.update(OFERTAS, doc_id, {'estado': str(EstadoOferta.RECHAZADA)})
