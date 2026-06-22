from core.realtime.notifier import SocketIORealtimeNotifier
from negotiation.application.usecases import (
    ConductorAceptarSolicitudUseCase,
    ConductorContraofertarUseCase,
    ConductorRechazarSolicitudUseCase,
    ListarOfertasParaPasajeroUseCase,
    SeleccionarConductorUseCase,
)
from negotiation.infrastructure.repositories import DjangoOfertaRepository
from trips.infrastructure.repositories import DjangoSolicitudViajeRepository, DjangoViajeRepository


class NegotiationService:
    """Fachada de la negociación de tarifas: punto único de entrada para
    las vistas, que orquesta los casos de uso sobre los repositorios y
    notifica los eventos en tiempo real correspondientes."""

    def __init__(self, oferta_repo=None, solicitud_repo=None, viaje_repo=None, notifier=None):
        self.oferta_repo = oferta_repo or DjangoOfertaRepository()
        self.solicitud_repo = solicitud_repo or DjangoSolicitudViajeRepository()
        self.viaje_repo = viaje_repo or DjangoViajeRepository()
        self.notifier = notifier or SocketIORealtimeNotifier()

    def aceptar(self, *, solicitud_id, conductor):
        usecase = ConductorAceptarSolicitudUseCase(
            self.oferta_repo, self.solicitud_repo, notifier=self.notifier,
        )
        return usecase.execute(solicitud_id=solicitud_id, conductor=conductor)

    def contraofertar(self, *, solicitud_id, conductor, tarifa):
        usecase = ConductorContraofertarUseCase(
            self.oferta_repo, self.solicitud_repo, notifier=self.notifier,
        )
        return usecase.execute(
            solicitud_id=solicitud_id, conductor=conductor, tarifa=tarifa,
        )

    def rechazar(self, *, solicitud_id, conductor):
        usecase = ConductorRechazarSolicitudUseCase(self.oferta_repo, self.solicitud_repo)
        return usecase.execute(solicitud_id=solicitud_id, conductor=conductor)

    def listar_ofertas(self, solicitud_id):
        usecase = ListarOfertasParaPasajeroUseCase(self.oferta_repo)
        return usecase.execute(solicitud_id)

    def seleccionar_conductor(self, *, oferta_id):
        usecase = SeleccionarConductorUseCase(
            self.oferta_repo, self.solicitud_repo, self.viaje_repo, notifier=self.notifier,
        )
        return usecase.execute(oferta_id=oferta_id)
