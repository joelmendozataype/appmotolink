class CrearSolicitudViajeUseCase:
    """1. El pasajero crea una solicitud proponiendo una tarifa."""

    def __init__(self, solicitud_repo, notifier=None):
        self.solicitud_repo = solicitud_repo
        self.notifier = notifier

    def execute(self, *, pasajero, origen, destino, tarifa_propuesta):
        solicitud = self.solicitud_repo.crear(
            pasajero=pasajero,
            origen=origen,
            destino=destino,
            tarifa_propuesta=tarifa_propuesta,
        )
        if self.notifier:
            self.notifier.notificar_solicitud_creada(solicitud)
        return solicitud


class ListarSolicitudesDisponiblesUseCase:
    """3. Los conductores visualizan las solicitudes activas."""

    def __init__(self, solicitud_repo):
        self.solicitud_repo = solicitud_repo

    def execute(self):
        return self.solicitud_repo.listar_disponibles()
