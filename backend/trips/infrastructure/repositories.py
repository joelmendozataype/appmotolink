from trips.domain.repositories import SolicitudViajeRepository, ViajeRepository
from trips.infrastructure.models import EstadoSolicitud, SolicitudViaje, Viaje


class DjangoSolicitudViajeRepository(SolicitudViajeRepository):
    def crear(self, *, pasajero, origen, destino, tarifa_propuesta):
        return SolicitudViaje.objects.create(
            pasajero=pasajero,
            origen=origen,
            destino=destino,
            tarifa_propuesta=tarifa_propuesta,
            estado=EstadoSolicitud.PENDIENTE,
        )

    def obtener_por_id(self, solicitud_id):
        return SolicitudViaje.objects.select_related('pasajero').get(id=solicitud_id)

    def listar_disponibles(self):
        return SolicitudViaje.objects.filter(
            estado__in=[EstadoSolicitud.PENDIENTE, EstadoSolicitud.EN_NEGOCIACION],
        )

    def guardar(self, solicitud):
        solicitud.save()
        return solicitud


class DjangoViajeRepository(ViajeRepository):
    def crear(self, *, solicitud, pasajero, conductor, tarifa_final):
        return Viaje.objects.create(
            solicitud=solicitud,
            pasajero=pasajero,
            conductor=conductor,
            tarifa_final=tarifa_final,
        )

    def obtener_por_id(self, viaje_id):
        return Viaje.objects.select_related('pasajero', 'conductor__usuario').get(
            id=viaje_id,
        )

    def guardar(self, viaje):
        viaje.save()
        return viaje
