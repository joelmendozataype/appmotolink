from rest_framework import status
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet

from core import di
from ratings.domain.repositories import CalificacionNoEncontradaError
from ratings.infrastructure.serializers import CalificacionSerializer


class CalificacionViewSet(ViewSet):
    serializer_class = CalificacionSerializer

    def list(self, request):
        calificaciones = di.calificacion_repo().listar(
            viaje_id=request.query_params.get('viajeId'),
        )
        return Response(CalificacionSerializer(calificaciones, many=True).data)

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
        calificacion = serializer.save()
        return Response(
            CalificacionSerializer(calificacion).data,
            status=status.HTTP_201_CREATED,
        )
