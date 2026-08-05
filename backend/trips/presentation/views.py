"""Vistas de solicitudes de viaje, viajes e historial.

Los tres tipos de error de negociación siguen mapeando a los mismos
códigos que antes: 404 si la solicitud o el conductor no existen, 409 si
la solicitud ya no está disponible o el conductor ya respondió.
"""
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet

from core import di
from core.realtime.notifier import SocketIORealtimeNotifier
from negotiation.application.services import NegotiationService
from negotiation.domain.exceptions import (
    OfertaDuplicadaError,
    SolicitudNoDisponibleError,
)
from negotiation.infrastructure.serializers import OfertaSerializer
from trips.application.usecases import (
    CrearSolicitudViajeUseCase,
    ListarSolicitudesDisponiblesUseCase,
)
from trips.domain.entities import EstadoViaje
from trips.domain.repositories import (
    SolicitudNoEncontradaError,
    ViajeNoEncontradoError,
)
from trips.infrastructure.serializers import SolicitudViajeSerializer, ViajeSerializer
from users.domain.repositories import MototaxistaNoEncontradoError

ESTADOS_VIAJE_ACTIVO = [EstadoViaje.ASIGNADO, EstadoViaje.EN_CURSO]


def _no_encontrado(detalle='No encontrado.'):
    return Response({'detail': detalle}, status=status.HTTP_404_NOT_FOUND)


def _conflicto(detalle):
    return Response({'detail': detalle}, status=status.HTTP_409_CONFLICT)


class SolicitudViajeViewSet(ViewSet):
    serializer_class = SolicitudViajeSerializer

    def list(self, request):
        solicitudes = ListarSolicitudesDisponiblesUseCase(di.solicitud_repo()).execute()
        return Response(SolicitudViajeSerializer(solicitudes, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            solicitud = di.solicitud_repo().obtener_por_id(pk)
        except SolicitudNoEncontradaError:
            return _no_encontrado()
        return Response(SolicitudViajeSerializer(solicitud).data)

    def create(self, request):
        serializer = SolicitudViajeSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        usecase = CrearSolicitudViajeUseCase(
            di.solicitud_repo(), notifier=SocketIORealtimeNotifier(),
        )
        solicitud = usecase.execute(
            pasajero=serializer.validated_data['pasajero_id'],
            origen=serializer.validated_data['origen'],
            destino=serializer.validated_data['destino'],
            tarifa_propuesta=serializer.validated_data['tarifa_propuesta'],
        )
        return Response(
            SolicitudViajeSerializer(solicitud).data, status=status.HTTP_201_CREATED,
        )

    def destroy(self, request, pk=None):
        try:
            di.solicitud_repo().eliminar(pk)
        except SolicitudNoEncontradaError:
            return _no_encontrado()
        return Response(status=status.HTTP_204_NO_CONTENT)

    def _conductor_de(self, request):
        return di.mototaxista_repo().obtener_por_id(request.data.get('conductor_id'))

    def _responder(self, request, pk, operacion, **extra):
        """Las tres respuestas del conductor (aceptar, contraofertar y
        rechazar) comparten exactamente el mismo manejo de errores."""
        try:
            oferta = operacion(
                solicitud_id=pk, conductor=self._conductor_de(request), **extra,
            )
        except (MototaxistaNoEncontradoError, SolicitudNoEncontradaError):
            return _no_encontrado('Solicitud o conductor no encontrado')
        except SolicitudNoDisponibleError:
            return _conflicto('La solicitud ya no está disponible')
        except OfertaDuplicadaError:
            return _conflicto('Ya respondiste a esta solicitud')
        return Response(OfertaSerializer(oferta).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def aceptar(self, request, pk=None):
        """4a. El conductor acepta la tarifa propuesta por el pasajero."""
        return self._responder(request, pk, NegotiationService().aceptar)

    @action(detail=True, methods=['post'])
    def contraofertar(self, request, pk=None):
        """4b. El conductor propone una tarifa distinta."""
        return self._responder(
            request, pk, NegotiationService().contraofertar,
            tarifa=request.data.get('tarifa'),
        )

    @action(detail=True, methods=['post'])
    def rechazar(self, request, pk=None):
        """4c. El conductor rechaza la solicitud."""
        return self._responder(request, pk, NegotiationService().rechazar)

    @action(detail=True, methods=['get'])
    def ofertas(self, request, pk=None):
        """5. El pasajero consulta las ofertas recibidas para su solicitud."""
        ofertas = NegotiationService().listar_ofertas(pk)
        return Response(OfertaSerializer(ofertas, many=True).data)


class ViajeViewSet(ViewSet):
    serializer_class = ViajeSerializer

    def list(self, request):
        viajes = di.viaje_repo().listar()
        return Response(ViajeSerializer(viajes, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            viaje = di.viaje_repo().obtener_por_id(pk)
        except ViajeNoEncontradoError:
            return _no_encontrado()
        return Response(ViajeSerializer(viaje).data)

    @action(detail=False, methods=['get'])
    def activo(self, request):
        viajes = di.viaje_repo().listar_por_usuario(
            request.query_params.get('usuarioId'), estados=ESTADOS_VIAJE_ACTIVO,
        )
        if not viajes:
            return Response(status=status.HTTP_404_NOT_FOUND)
        return Response(ViajeSerializer(viajes[0]).data)

    @action(detail=True, methods=['put'])
    def finalizar(self, request, pk=None):
        repo = di.viaje_repo()
        try:
            viaje = repo.obtener_por_id(pk)
        except ViajeNoEncontradoError:
            return _no_encontrado()
        viaje.estado = EstadoViaje.FINALIZADO
        repo.guardar(viaje)
        return Response(ViajeSerializer(viaje).data)


class HistorialView(ViewSet):
    serializer_class = ViajeSerializer

    def list(self, request):
        usuario_id = request.query_params.get('usuarioId')
        viajes = di.viaje_repo().listar_por_usuario(usuario_id)
        return Response({
            'id': usuario_id,
            'viajes': ViajeSerializer(viajes, many=True).data,
        })
