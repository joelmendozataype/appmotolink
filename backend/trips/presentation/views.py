from django.core.exceptions import ObjectDoesNotExist
from django.db.models import Q
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

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
from trips.infrastructure.models import EstadoViaje, SolicitudViaje, Viaje
from trips.infrastructure.repositories import DjangoSolicitudViajeRepository
from trips.infrastructure.serializers import SolicitudViajeSerializer, ViajeSerializer
from users.infrastructure.models import Mototaxista


class SolicitudViajeViewSet(ModelViewSet):
    queryset = SolicitudViaje.objects.all()
    serializer_class = SolicitudViajeSerializer

    def get_queryset(self):
        if self.action == 'list':
            return ListarSolicitudesDisponiblesUseCase(
                DjangoSolicitudViajeRepository(),
            ).execute()
        return super().get_queryset()

    def create(self, request, *args, **kwargs):
        serializer = self.get_serializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        usecase = CrearSolicitudViajeUseCase(
            DjangoSolicitudViajeRepository(), notifier=SocketIORealtimeNotifier(),
        )
        solicitud = usecase.execute(
            pasajero=serializer.validated_data['pasajero'],
            origen=serializer.validated_data['origen'],
            destino=serializer.validated_data['destino'],
            tarifa_propuesta=serializer.validated_data['tarifa_propuesta'],
        )
        return Response(
            self.get_serializer(solicitud).data, status=status.HTTP_201_CREATED,
        )

    def _conductor_de(self, request):
        conductor_id = request.data.get('conductor_id')
        return Mototaxista.objects.select_related('usuario').get(
            usuario_id=conductor_id,
        )

    @action(detail=True, methods=['post'])
    def aceptar(self, request, pk=None):
        """4a. El conductor acepta la tarifa propuesta por el pasajero."""
        try:
            oferta = NegotiationService().aceptar(
                solicitud_id=pk, conductor=self._conductor_de(request),
            )
        except ObjectDoesNotExist:
            return Response(
                {'detail': 'Solicitud o conductor no encontrado'},
                status=status.HTTP_404_NOT_FOUND,
            )
        except SolicitudNoDisponibleError:
            return Response(
                {'detail': 'La solicitud ya no está disponible'},
                status=status.HTTP_409_CONFLICT,
            )
        except OfertaDuplicadaError:
            return Response(
                {'detail': 'Ya respondiste a esta solicitud'},
                status=status.HTTP_409_CONFLICT,
            )
        return Response(OfertaSerializer(oferta).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def contraofertar(self, request, pk=None):
        """4b. El conductor propone una tarifa distinta."""
        tarifa = request.data.get('tarifa')
        try:
            oferta = NegotiationService().contraofertar(
                solicitud_id=pk, conductor=self._conductor_de(request), tarifa=tarifa,
            )
        except ObjectDoesNotExist:
            return Response(
                {'detail': 'Solicitud o conductor no encontrado'},
                status=status.HTTP_404_NOT_FOUND,
            )
        except SolicitudNoDisponibleError:
            return Response(
                {'detail': 'La solicitud ya no está disponible'},
                status=status.HTTP_409_CONFLICT,
            )
        except OfertaDuplicadaError:
            return Response(
                {'detail': 'Ya respondiste a esta solicitud'},
                status=status.HTTP_409_CONFLICT,
            )
        return Response(OfertaSerializer(oferta).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['post'])
    def rechazar(self, request, pk=None):
        """4c. El conductor rechaza la solicitud."""
        try:
            oferta = NegotiationService().rechazar(
                solicitud_id=pk, conductor=self._conductor_de(request),
            )
        except ObjectDoesNotExist:
            return Response(
                {'detail': 'Solicitud o conductor no encontrado'},
                status=status.HTTP_404_NOT_FOUND,
            )
        except SolicitudNoDisponibleError:
            return Response(
                {'detail': 'La solicitud ya no está disponible'},
                status=status.HTTP_409_CONFLICT,
            )
        except OfertaDuplicadaError:
            return Response(
                {'detail': 'Ya respondiste a esta solicitud'},
                status=status.HTTP_409_CONFLICT,
            )
        return Response(OfertaSerializer(oferta).data, status=status.HTTP_201_CREATED)

    @action(detail=True, methods=['get'])
    def ofertas(self, request, pk=None):
        """5. El pasajero consulta las ofertas recibidas para su solicitud."""
        ofertas = NegotiationService().listar_ofertas(pk)
        return Response(OfertaSerializer(ofertas, many=True).data)


class ViajeViewSet(ModelViewSet):
    queryset = Viaje.objects.all()
    serializer_class = ViajeSerializer

    @action(detail=False, methods=['get'])
    def activo(self, request):
        usuario_id = request.query_params.get('usuarioId')
        viaje = Viaje.objects.filter(
            Q(pasajero_id=usuario_id) | Q(conductor__usuario_id=usuario_id),
            estado__in=[EstadoViaje.ASIGNADO, EstadoViaje.EN_CURSO],
        ).first()
        if viaje is None:
            return Response(status=404)
        return Response(ViajeSerializer(viaje).data)

    @action(detail=True, methods=['put'])
    def finalizar(self, request, pk=None):
        viaje = self.get_object()
        viaje.estado = EstadoViaje.FINALIZADO
        viaje.save()
        return Response(ViajeSerializer(viaje).data)


class HistorialView(ModelViewSet):
    http_method_names = ['get']
    serializer_class = ViajeSerializer

    def get_queryset(self):
        usuario_id = self.request.query_params.get('usuarioId')
        return Viaje.objects.filter(
            Q(pasajero_id=usuario_id) | Q(conductor__usuario_id=usuario_id),
        )

    def list(self, request, *args, **kwargs):
        viajes = self.get_queryset()
        return Response({
            'id': request.query_params.get('usuarioId'),
            'viajes': ViajeSerializer(viajes, many=True).data,
        })
