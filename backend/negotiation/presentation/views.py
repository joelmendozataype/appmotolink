from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet

from core import di
from negotiation.application.services import NegotiationService
from negotiation.domain.exceptions import (
    OfertaNoDisponibleError,
    SolicitudNoDisponibleError,
)
from negotiation.domain.repositories import OfertaNoEncontradaError
from negotiation.infrastructure.serializers import OfertaSerializer
from trips.domain.repositories import SolicitudNoEncontradaError
from trips.infrastructure.serializers import ViajeSerializer


class OfertaViewSet(ViewSet):
    serializer_class = OfertaSerializer

    def list(self, request):
        repo = di.oferta_repo()
        solicitud_id = request.query_params.get('solicitudId')
        if solicitud_id:
            ofertas = repo.listar_por_solicitud(solicitud_id, solo_pendientes=True)
        else:
            ofertas = repo.listar_pendientes()
        return Response(OfertaSerializer(ofertas, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            oferta = di.oferta_repo().obtener_por_id(pk)
        except OfertaNoEncontradaError:
            return Response(
                {'detail': 'La oferta no existe'}, status=status.HTTP_404_NOT_FOUND,
            )
        return Response(OfertaSerializer(oferta).data)

    @action(detail=True, methods=['post'])
    def seleccionar(self, request, pk=None):
        """6-7. El pasajero selecciona esta oferta: el viaje queda asignado."""
        try:
            viaje = NegotiationService().seleccionar_conductor(oferta_id=pk)
        except (OfertaNoEncontradaError, SolicitudNoEncontradaError):
            return Response(
                {'detail': 'La oferta no existe'}, status=status.HTTP_404_NOT_FOUND,
            )
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
