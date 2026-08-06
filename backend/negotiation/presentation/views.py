from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet

from core import di
from core.permissions import es_administrador
from negotiation.application.services import NegotiationService
from negotiation.domain.exceptions import (
    OfertaNoDisponibleError,
    SolicitudNoDisponibleError,
)
from negotiation.domain.repositories import OfertaNoEncontradaError
from negotiation.infrastructure.serializers import OfertaSerializer
from trips.domain.repositories import SolicitudNoEncontradaError
from trips.infrastructure.serializers import ViajeSerializer


def _prohibido(detalle='No tienes permiso para acceder a este recurso.'):
    return Response({'detail': detalle}, status=status.HTTP_403_FORBIDDEN)


def _puede_ver(usuario, oferta):
    """Una oferta la ven su conductor y el pasajero de la solicitud."""
    if es_administrador(usuario):
        return True
    usuario_id = str(usuario.id)
    if usuario_id == str(oferta.conductor_id):
        return True
    solicitud = oferta.solicitud
    return solicitud is not None and usuario_id == str(solicitud.pasajero_id)


class OfertaViewSet(ViewSet):
    serializer_class = OfertaSerializer

    def list(self, request):
        repo = di.oferta_repo()
        solicitud_id = request.query_params.get('solicitudId')
        if solicitud_id:
            ofertas = repo.listar_por_solicitud(solicitud_id, solo_pendientes=True)
        else:
            ofertas = repo.listar_pendientes()
        # Se filtra por visibilidad: antes cualquiera podía leer todas las
        # ofertas pendientes del sistema, con nombre y placa del conductor.
        ofertas = [o for o in ofertas if _puede_ver(request.user, o)]
        return Response(OfertaSerializer(ofertas, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            oferta = di.oferta_repo().obtener_por_id(pk)
        except OfertaNoEncontradaError:
            return Response(
                {'detail': 'La oferta no existe'}, status=status.HTTP_404_NOT_FOUND,
            )
        if not _puede_ver(request.user, oferta):
            return _prohibido()
        return Response(OfertaSerializer(oferta).data)

    @action(detail=True, methods=['post'])
    def seleccionar(self, request, pk=None):
        """6-7. El pasajero selecciona esta oferta: el viaje queda asignado."""
        try:
            # Solo el pasajero dueño de la solicitud elige conductor.
            oferta = di.oferta_repo().obtener_por_id(pk)
            solicitud = oferta.solicitud
            if solicitud is None:
                raise SolicitudNoEncontradaError(oferta.solicitud_id)
            if str(solicitud.pasajero_id) != str(request.user.id):
                return _prohibido('Esta solicitud no es tuya.')

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
