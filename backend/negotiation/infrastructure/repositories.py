from negotiation.domain.repositories import OfertaRepository
from negotiation.infrastructure.models import EstadoOferta, Oferta


class DjangoOfertaRepository(OfertaRepository):
    def crear(self, *, solicitud, conductor, tarifa, tipo):
        return Oferta.objects.create(
            solicitud=solicitud,
            conductor=conductor,
            tarifa=tarifa,
            tipo=tipo,
        )

    def obtener_por_id(self, oferta_id):
        return Oferta.objects.select_related(
            'conductor__usuario', 'solicitud',
        ).get(id=oferta_id)

    def listar_por_solicitud(self, solicitud_id, *, solo_pendientes=True):
        queryset = Oferta.objects.filter(solicitud_id=solicitud_id)
        if solo_pendientes:
            queryset = queryset.filter(estado=EstadoOferta.PENDIENTE)
        return queryset.select_related('conductor__usuario')

    def buscar_de_conductor(self, solicitud_id, conductor_id):
        return Oferta.objects.filter(
            solicitud_id=solicitud_id, conductor_id=conductor_id,
        ).first()

    def guardar(self, oferta):
        oferta.save()
        return oferta

    def rechazar_otras(self, solicitud_id, oferta_ganadora_id):
        Oferta.objects.filter(solicitud_id=solicitud_id).exclude(
            id=oferta_ganadora_id,
        ).update(estado=EstadoOferta.RECHAZADA)
