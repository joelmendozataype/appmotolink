from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from negotiation.application.services import NegotiationService
from negotiation.domain.exceptions import OfertaNoDisponibleError, SolicitudNoDisponibleError
from negotiation.infrastructure.models import EstadoOferta, Oferta
from negotiation.infrastructure.serializers import OfertaSerializer
from trips.infrastructure.serializers import ViajeSerializer


class OfertaViewSet(ModelViewSet):
    queryset = Oferta.objects.all()
    serializer_class = OfertaSerializer
    http_method_names = ['get', 'post']

    def get_queryset(self):
        queryset = Oferta.objects.filter(estado=EstadoOferta.PENDIENTE)
        solicitud_id = self.request.query_params.get('solicitudId')
        if solicitud_id:
            queryset = queryset.filter(solicitud_id=solicitud_id)
        return queryset

    @action(detail=True, methods=['post'])
    def seleccionar(self, request, pk=None):
        """6-7. El pasajero selecciona esta oferta: el viaje queda asignado."""
        try:
            viaje = NegotiationService().seleccionar_conductor(oferta_id=pk)
        except OfertaNoDisponibleError:
            return Response(
                {'detail': 'Esta oferta ya no está disponible'},
                status=status.HTTP_409_CONFLICT,
            )
        except SolicitudNoDisponibleError:
            return Response(
                {'detail': 'La solicitud ya no está disponible'},
                status=status.HTTP_409_CONFLICT,
            )
        return Response(ViajeSerializer(viaje).data, status=status.HTTP_201_CREATED)
