from rest_framework import serializers

from core import di
from ratings.domain.entities import (
    PUNTUACION_MAXIMA,
    PUNTUACION_MINIMA,
    Calificacion,
)
from ratings.domain.repositories import ViajeYaCalificadoError


class CalificacionSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    viaje = serializers.CharField(source='viaje_id')
    # El rango 1..5 ahora se valida también en la entidad; aquí se declara
    # para que la API devuelva 400 con mensaje en vez de un 500.
    puntuacion = serializers.IntegerField(
        min_value=PUNTUACION_MINIMA, max_value=PUNTUACION_MAXIMA,
    )
    comentario = serializers.CharField(
        max_length=500, allow_blank=True, required=False, default='',
    )
    fecha = serializers.DateTimeField(read_only=True)

    def create(self, validated_data):
        calificacion = Calificacion(
            viaje_id=validated_data['viaje_id'],
            puntuacion=validated_data['puntuacion'],
            comentario=validated_data.get('comentario', ''),
        )
        try:
            return di.calificacion_repo().crear(calificacion)
        except ViajeYaCalificadoError:
            raise serializers.ValidationError(
                {'viaje': ['Este viaje ya tiene una calificación.']},
            )
