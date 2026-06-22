from rest_framework import serializers
from users.infrastructure.serializers import MototaxistaSerializer

from .models import Oferta


class OfertaSerializer(serializers.ModelSerializer):
    conductor = MototaxistaSerializer(read_only=True)

    class Meta:
        model = Oferta
        fields = ['id', 'solicitud', 'conductor', 'tarifa', 'tipo', 'estado', 'fecha']
