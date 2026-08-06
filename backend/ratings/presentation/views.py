from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet

from core import di
from core.permissions import es_administrador
from ratings.domain.repositories import CalificacionNoEncontradaError
from ratings.infrastructure.serializers import CalificacionSerializer
from trips.domain.entities import EstadoViaje
from trips.domain.repositories import ViajeNoEncontradoError


def _prohibido(detalle='No tienes permiso para acceder a este recurso.'):
    return Response({'detail': detalle}, status=status.HTTP_403_FORBIDDEN)


class CalificacionViewSet(ViewSet):
    serializer_class = CalificacionSerializer

    def list(self, request):
        # El listado completo es de administración. Un usuario normal solo
        # consulta la calificación de un viaje suyo.
        viaje_id = request.query_params.get('viajeId')
        if es_administrador(request.user):
            return Response(
                CalificacionSerializer(
                    di.calificacion_repo().listar(viaje_id=viaje_id), many=True,
                ).data,
            )
        if not viaje_id:
            return _prohibido('Indica el viaje con ?viajeId=')
        try:
            viaje = di.viaje_repo().obtener_por_id(viaje_id)
        except ViajeNoEncontradoError:
            return Response([])
        if str(viaje.pasajero_id) != str(request.user.id) and str(
            viaje.conductor_id,
        ) != str(request.user.id):
            return _prohibido()
        return Response(
            CalificacionSerializer(
                di.calificacion_repo().listar(viaje_id=viaje_id), many=True,
            ).data,
        )

    def retrieve(self, request, pk=None):
        try:
            calificacion = di.calificacion_repo().obtener_por_id(pk)
        except CalificacionNoEncontradaError:
            return Response(
                {'detail': 'No encontrado.'}, status=status.HTTP_404_NOT_FOUND,
            )
        return Response(CalificacionSerializer(calificacion).data)

    def create(self, request):
        serializer = CalificacionSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)

        # Solo el pasajero de ese viaje lo califica, y solo cuando ya
        # terminó. Antes se aceptaba cualquier viaje de cualquiera.
        viaje_id = serializer.validated_data['viaje_id']
        try:
            viaje = di.viaje_repo().obtener_por_id(viaje_id)
        except ViajeNoEncontradoError:
            return Response(
                {'viaje': ['El viaje no existe.']},
                status=status.HTTP_400_BAD_REQUEST,
            )
        if str(viaje.pasajero_id) != str(request.user.id):
            return _prohibido('Solo el pasajero del viaje puede calificarlo.')
        if viaje.estado != EstadoViaje.FINALIZADO:
            return Response(
                {'viaje': ['Solo se puede calificar un viaje finalizado.']},
                status=status.HTTP_400_BAD_REQUEST,
            )

        calificacion = serializer.save()
        return Response(
            CalificacionSerializer(calificacion).data,
            status=status.HTTP_201_CREATED,
        )
