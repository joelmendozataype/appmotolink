from rest_framework import serializers

from .models import Calificacion


class CalificacionSerializer(serializers.ModelSerializer):
    class Meta:
        model = Calificacion
        fields = ['id', 'viaje', 'puntuacion', 'comentario', 'fecha']
        read_only_fields = ['id', 'fecha']
