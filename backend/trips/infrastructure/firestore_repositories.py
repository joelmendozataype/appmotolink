"""Repositorios de solicitudes y viajes sobre Firestore."""
from core.firestore import Filtro, get_store
from core.firestore.campos import a_datetime, a_decimal, a_float, a_texto_id, ahora
from core.firestore.colecciones import SOLICITUDES, VIAJES
from trips.domain.entities import EstadoSolicitud, EstadoViaje, SolicitudViaje, Viaje
from trips.domain.repositories import (
    SolicitudNoEncontradaError,
    SolicitudViajeRepository,
    ViajeNoEncontradoError,
    ViajeRepository,
)
from users.domain.repositories import (
    MototaxistaNoEncontradoError,
    UsuarioNoEncontradoError,
)
from users.infrastructure.firestore_repositories import (
    FirestoreMototaxistaRepository,
    FirestoreUsuarioRepository,
)

ESTADOS_DISPONIBLES = [
    str(EstadoSolicitud.PENDIENTE),
    str(EstadoSolicitud.EN_NEGOCIACION),
]


def _mas_recientes_primero(elementos):
    """Ordena por fecha de creación, de la más nueva a la más vieja.

    Se ordena aquí y no en la consulta porque combinar un filtro con un
    `order_by` en Firestore exige declarar un índice compuesto a mano; el
    resultado es pequeño y ordenarlo en memoria sale más barato.

    Los registros migrados desde SQLite no tienen fecha —aquella base no
    la guardaba— y se van al final en vez de romper la comparación.
    """
    return sorted(
        elementos,
        key=lambda e: (e.creado_en is not None, e.creado_en),
        reverse=True,
    )


class FirestoreSolicitudViajeRepository(SolicitudViajeRepository):
    def __init__(self, store=None, usuario_repo=None):
        self._store_inyectado = store
        self.usuario_repo = usuario_repo or FirestoreUsuarioRepository(store)

    @property
    def store(self):
        return self._store_inyectado or get_store()

    @staticmethod
    def _a_documento(solicitud):
        return {
            'pasajero_id': a_texto_id(solicitud.pasajero_id),
            'origen': solicitud.origen,
            'destino': solicitud.destino,
            'tarifa_propuesta': a_float(solicitud.tarifa_propuesta),
            'estado': str(solicitud.estado),
            'creado_en': solicitud.creado_en,
        }

    def _a_entidad(self, doc_id, datos, *, con_pasajero=True):
        solicitud = SolicitudViaje(
            id=a_texto_id(doc_id),
            pasajero_id=datos.get('pasajero_id'),
            origen=datos.get('origen', ''),
            destino=datos.get('destino', ''),
            tarifa_propuesta=a_decimal(datos.get('tarifa_propuesta')),
            estado=datos.get('estado', EstadoSolicitud.PENDIENTE),
            creado_en=a_datetime(datos.get('creado_en')),
        )
        if con_pasajero and solicitud.pasajero_id:
            try:
                solicitud.pasajero = self.usuario_repo.obtener_por_id(
                    solicitud.pasajero_id,
                )
            except UsuarioNoEncontradoError:
                solicitud.pasajero = None
        return solicitud

    def crear(self, *, pasajero, origen, destino, tarifa_propuesta):
        pasajero_id = getattr(pasajero, 'id', pasajero)
        solicitud = SolicitudViaje(
            pasajero_id=a_texto_id(pasajero_id),
            origen=origen,
            destino=destino,
            tarifa_propuesta=a_decimal(tarifa_propuesta),
            estado=EstadoSolicitud.PENDIENTE,
            creado_en=ahora(),
        )
        solicitud.pasajero = pasajero if hasattr(pasajero, 'nombre') else None
        self.store.set(SOLICITUDES, solicitud.id, self._a_documento(solicitud))
        return solicitud

    def obtener_por_id(self, solicitud_id):
        solicitud_id = a_texto_id(solicitud_id)
        datos = self.store.get(SOLICITUDES, solicitud_id)
        if datos is None:
            raise SolicitudNoEncontradaError(solicitud_id)
        return self._a_entidad(solicitud_id, datos)

    def _hidratar(self, documentos, *, con_pasajero=True):
        """Hidrata los pasajeros de una lista con una sola lectura por lote
        (equivalente al select_related del ORM)."""
        documentos = list(documentos)
        solicitudes = [
            self._a_entidad(doc_id, datos, con_pasajero=False)
            for doc_id, datos in documentos
        ]
        if not con_pasajero:
            return _mas_recientes_primero(solicitudes)
        pasajeros = self.usuario_repo.obtener_varios(
            [s.pasajero_id for s in solicitudes],
        )
        for solicitud in solicitudes:
            solicitud.pasajero = pasajeros.get(a_texto_id(solicitud.pasajero_id))
        return _mas_recientes_primero(solicitudes)

    def listar_disponibles(self):
        filtros = [Filtro('estado', 'in', ESTADOS_DISPONIBLES)]
        return self._hidratar(self.store.query(SOLICITUDES, filtros))

    def listar(self):
        return self._hidratar(self.store.query(SOLICITUDES))

    def obtener_varias(self, solicitud_ids, *, con_pasajero=True):
        documentos = self.store.get_many(
            SOLICITUDES, [a_texto_id(i) for i in solicitud_ids],
        )
        solicitudes = self._hidratar(
            documentos.items(), con_pasajero=con_pasajero,
        )
        return {s.id: s for s in solicitudes}

    def guardar(self, solicitud):
        self.store.set(SOLICITUDES, solicitud.id, self._a_documento(solicitud))
        return solicitud

    def eliminar(self, solicitud_id):
        solicitud_id = a_texto_id(solicitud_id)
        if self.store.get(SOLICITUDES, solicitud_id) is None:
            raise SolicitudNoEncontradaError(solicitud_id)
        self.store.delete(SOLICITUDES, solicitud_id)

    def cerrar_si_disponible(self, solicitud_id, estados_aceptables, nuevo_estado):
        return self.store.compare_and_set(
            SOLICITUDES,
            a_texto_id(solicitud_id),
            'estado',
            [str(estado) for estado in estados_aceptables],
            {'estado': str(nuevo_estado)},
        )


class FirestoreViajeRepository(ViajeRepository):
    def __init__(self, store=None, usuario_repo=None, mototaxista_repo=None,
                 solicitud_repo=None):
        self._store_inyectado = store
        self.usuario_repo = usuario_repo or FirestoreUsuarioRepository(store)
        self.mototaxista_repo = mototaxista_repo or FirestoreMototaxistaRepository(store)
        self.solicitud_repo = solicitud_repo or FirestoreSolicitudViajeRepository(store)

    @property
    def store(self):
        return self._store_inyectado or get_store()

    @staticmethod
    def _a_documento(viaje):
        return {
            'solicitud_id': a_texto_id(viaje.solicitud_id),
            'pasajero_id': a_texto_id(viaje.pasajero_id),
            'conductor_id': a_texto_id(viaje.conductor_id),
            'tarifa_final': a_float(viaje.tarifa_final),
            'estado': str(viaje.estado),
            'creado_en': viaje.creado_en,
            'finalizado_en': viaje.finalizado_en,
        }

    def _a_entidad(self, doc_id, datos, *, hidratar=True):
        viaje = Viaje(
            id=a_texto_id(doc_id),
            solicitud_id=datos.get('solicitud_id'),
            pasajero_id=datos.get('pasajero_id'),
            conductor_id=datos.get('conductor_id'),
            tarifa_final=a_decimal(datos.get('tarifa_final')),
            estado=datos.get('estado', EstadoViaje.ASIGNADO),
            creado_en=a_datetime(datos.get('creado_en')),
            finalizado_en=a_datetime(datos.get('finalizado_en')),
        )
        if not hidratar:
            # El llamador hidrata en lote (ver _hidratar).
            return viaje
        # Hidratación equivalente al select_related del ORM: el
        # ViajeSerializer expone pasajero y conductor anidados.
        try:
            viaje.pasajero = self.usuario_repo.obtener_por_id(viaje.pasajero_id)
        except UsuarioNoEncontradoError:
            viaje.pasajero = None
        try:
            viaje.conductor = self.mototaxista_repo.obtener_por_id(viaje.conductor_id)
        except MototaxistaNoEncontradoError:
            viaje.conductor = None
        return viaje

    def crear(self, *, solicitud, pasajero, conductor, tarifa_final):
        viaje = Viaje(
            solicitud_id=a_texto_id(getattr(solicitud, 'id', solicitud)),
            pasajero_id=a_texto_id(getattr(pasajero, 'id', pasajero)),
            conductor_id=a_texto_id(getattr(conductor, 'usuario_id', conductor)),
            tarifa_final=a_decimal(tarifa_final),
            estado=EstadoViaje.ASIGNADO,
            creado_en=ahora(),
        )
        viaje.solicitud = solicitud if hasattr(solicitud, 'origen') else None
        viaje.pasajero = pasajero if hasattr(pasajero, 'nombre') else None
        viaje.conductor = conductor if hasattr(conductor, 'placa') else None
        self.store.set(VIAJES, viaje.id, self._a_documento(viaje))
        return viaje

    def obtener_por_id(self, viaje_id):
        viaje_id = a_texto_id(viaje_id)
        datos = self.store.get(VIAJES, viaje_id)
        if datos is None:
            raise ViajeNoEncontradoError(viaje_id)
        return self._a_entidad(viaje_id, datos)

    def _hidratar(self, documentos):
        """Dos lecturas por lote (usuarios y mototaxistas) para toda la
        lista, en vez de dos por viaje."""
        documentos = list(documentos)
        viajes = [
            self._a_entidad(doc_id, datos, hidratar=False)
            for doc_id, datos in documentos
        ]
        pasajeros = self.usuario_repo.obtener_varios([v.pasajero_id for v in viajes])
        conductores = self.mototaxista_repo.obtener_varios(
            [v.conductor_id for v in viajes],
        )
        for viaje in viajes:
            viaje.pasajero = pasajeros.get(a_texto_id(viaje.pasajero_id))
            viaje.conductor = conductores.get(a_texto_id(viaje.conductor_id))

        # Más recientes primero, que es como se espera leer un historial.
        return _mas_recientes_primero(viajes)

    def listar(self):
        return self._hidratar(self.store.query(VIAJES))

    def listar_por_usuario(self, usuario_id, *, estados=None):
        """Firestore no tiene OR entre campos distintos sin índice
        compuesto, así que se hacen dos consultas y se unen aquí. El
        filtro por estado también se aplica en memoria: el resultado por
        usuario es chico y así no hace falta ningún índice extra."""
        usuario_id = a_texto_id(usuario_id)
        if not usuario_id:
            return []

        encontrados = {}
        for campo in ('pasajero_id', 'conductor_id'):
            for doc_id, datos in self.store.query(
                VIAJES, [Filtro(campo, '==', usuario_id)],
            ):
                encontrados[doc_id] = datos

        if estados is not None:
            aceptables = {str(estado) for estado in estados}
            encontrados = {
                doc_id: datos
                for doc_id, datos in encontrados.items()
                if datos.get('estado') in aceptables
            }

        return self._hidratar(encontrados.items())

    def guardar(self, viaje):
        self.store.set(VIAJES, viaje.id, self._a_documento(viaje))
        return viaje

    def cerrar_si_activo(self, viaje_id, nuevo_estado, momento):
        """Un viaje solo se cierra una vez: si ya está finalizado o
        cancelado, la segunda pulsación no hace nada."""
        return self.store.compare_and_set(
            VIAJES,
            a_texto_id(viaje_id),
            'estado',
            [str(EstadoViaje.ASIGNADO), str(EstadoViaje.EN_CURSO)],
            {'estado': str(nuevo_estado), 'finalizado_en': momento},
        )

    def eliminar(self, viaje_id):
        viaje_id = a_texto_id(viaje_id)
        if self.store.get(VIAJES, viaje_id) is None:
            raise ViajeNoEncontradoError(viaje_id)
        self.store.delete(VIAJES, viaje_id)
