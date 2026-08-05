from negotiation.domain.exceptions import (
    OfertaDuplicadaError,
    OfertaNoDisponibleError,
    SolicitudNoDisponibleError,
)
from negotiation.domain.entities import EstadoOferta, TipoOferta
from trips.domain.entities import EstadoSolicitud
from trips.domain.repositories import SolicitudNoEncontradaError

SOLICITUD_RESPONDIBLE = (EstadoSolicitud.PENDIENTE, EstadoSolicitud.EN_NEGOCIACION)


def _abrir_negociacion(solicitud, solicitud_repo):
    """Al llegar la primera respuesta, la solicitud pasa a 'en negociación'.

    Se hace con el cambio de estado condicional en vez de un guardar()
    completo: si entre medias la solicitud ya fue aceptada o cancelada,
    esta transición simplemente no se aplica en lugar de pisarla.
    """
    if solicitud.estado != EstadoSolicitud.PENDIENTE:
        return
    if solicitud_repo.cerrar_si_disponible(
        solicitud.id, [EstadoSolicitud.PENDIENTE], EstadoSolicitud.EN_NEGOCIACION,
    ):
        solicitud.estado = EstadoSolicitud.EN_NEGOCIACION


class ConductorAceptarSolicitudUseCase:
    """4a. El conductor acepta la tarifa propuesta por el pasajero tal cual."""

    def __init__(self, oferta_repo, solicitud_repo, notifier=None):
        self.oferta_repo = oferta_repo
        self.solicitud_repo = solicitud_repo
        self.notifier = notifier

    def execute(self, *, solicitud_id, conductor):
        solicitud = self.solicitud_repo.obtener_por_id(solicitud_id)
        if solicitud.estado not in SOLICITUD_RESPONDIBLE:
            raise SolicitudNoDisponibleError

        if self.oferta_repo.buscar_de_conductor(solicitud_id, conductor.usuario_id):
            raise OfertaDuplicadaError

        oferta = self.oferta_repo.crear(
            solicitud=solicitud,
            conductor=conductor,
            tarifa=solicitud.tarifa_propuesta,
            tipo=TipoOferta.ACEPTACION,
        )
        _abrir_negociacion(solicitud, self.solicitud_repo)
        if self.notifier:
            self.notifier.notificar_oferta_creada(oferta)
        return oferta


class ConductorContraofertarUseCase:
    """4b. El conductor propone una tarifa distinta a la del pasajero."""

    def __init__(self, oferta_repo, solicitud_repo, notifier=None):
        self.oferta_repo = oferta_repo
        self.solicitud_repo = solicitud_repo
        self.notifier = notifier

    def execute(self, *, solicitud_id, conductor, tarifa):
        solicitud = self.solicitud_repo.obtener_por_id(solicitud_id)
        if solicitud.estado not in SOLICITUD_RESPONDIBLE:
            raise SolicitudNoDisponibleError

        if self.oferta_repo.buscar_de_conductor(solicitud_id, conductor.usuario_id):
            raise OfertaDuplicadaError

        oferta = self.oferta_repo.crear(
            solicitud=solicitud,
            conductor=conductor,
            tarifa=tarifa,
            tipo=TipoOferta.CONTRAOFERTA,
        )
        _abrir_negociacion(solicitud, self.solicitud_repo)
        if self.notifier:
            self.notifier.notificar_contraoferta_creada(oferta)
        return oferta


class ConductorRechazarSolicitudUseCase:
    """4c. El conductor declina la solicitud; no se la vuelve a ofrecer."""

    def __init__(self, oferta_repo, solicitud_repo):
        self.oferta_repo = oferta_repo
        self.solicitud_repo = solicitud_repo

    def execute(self, *, solicitud_id, conductor):
        solicitud = self.solicitud_repo.obtener_por_id(solicitud_id)
        if solicitud.estado not in SOLICITUD_RESPONDIBLE:
            raise SolicitudNoDisponibleError

        if self.oferta_repo.buscar_de_conductor(solicitud_id, conductor.usuario_id):
            raise OfertaDuplicadaError

        oferta = self.oferta_repo.crear(
            solicitud=solicitud,
            conductor=conductor,
            tarifa=solicitud.tarifa_propuesta,
            tipo=TipoOferta.RECHAZO,
        )
        oferta.estado = EstadoOferta.RECHAZADA
        self.oferta_repo.guardar(oferta)
        # El rechazo no tiene evento en tiempo real: es información privada
        # del conductor, no algo que el pasajero deba ver llegar.
        return oferta


class ListarOfertasParaPasajeroUseCase:
    """5. El pasajero recibe las ofertas pendientes (aceptaciones y contraofertas)."""

    def __init__(self, oferta_repo):
        self.oferta_repo = oferta_repo

    def execute(self, solicitud_id):
        return self.oferta_repo.listar_por_solicitud(solicitud_id, solo_pendientes=True)


class SeleccionarConductorUseCase:
    """6-7. El pasajero elige una oferta y el viaje queda asignado."""

    def __init__(self, oferta_repo, solicitud_repo, viaje_repo, notifier=None):
        self.oferta_repo = oferta_repo
        self.solicitud_repo = solicitud_repo
        self.viaje_repo = viaje_repo
        self.notifier = notifier

    def execute(self, *, oferta_id):
        oferta = self.oferta_repo.obtener_por_id(oferta_id)
        solicitud = oferta.solicitud
        if solicitud is None:
            # La oferta apunta a una solicitud que ya no existe.
            raise SolicitudNoEncontradaError(oferta.solicitud_id)

        # Se cierra la solicitud primero y de forma atómica: es el recurso
        # por el que compiten las selecciones concurrentes. Si otro
        # pasajero (o un doble tap) llegó antes, aquí se corta.
        if not self.solicitud_repo.cerrar_si_disponible(
            solicitud.id, SOLICITUD_RESPONDIBLE, EstadoSolicitud.ACEPTADA,
        ):
            raise SolicitudNoDisponibleError

        # La solicitud ya es nuestra; ahora la oferta elegida debe seguir
        # pendiente (no haber sido rechazada entre medias).
        if not self.oferta_repo.aceptar_si_pendiente(oferta.id):
            # Se devuelve la solicitud a negociación para no dejarla
            # cerrada sin viaje asignado.
            self.solicitud_repo.cerrar_si_disponible(
                solicitud.id, [EstadoSolicitud.ACEPTADA], EstadoSolicitud.EN_NEGOCIACION,
            )
            raise OfertaNoDisponibleError

        oferta.estado = EstadoOferta.ACEPTADA
        solicitud.estado = EstadoSolicitud.ACEPTADA
        self.oferta_repo.rechazar_otras(solicitud.id, oferta.id)

        viaje = self.viaje_repo.crear(
            solicitud=solicitud,
            pasajero=solicitud.pasajero or solicitud.pasajero_id,
            conductor=oferta.conductor or oferta.conductor_id,
            tarifa_final=oferta.tarifa,
        )

        if self.notifier:
            self.notifier.notificar_oferta_aceptada(oferta)
            self.notifier.notificar_viaje_asignado(viaje)

        return viaje
