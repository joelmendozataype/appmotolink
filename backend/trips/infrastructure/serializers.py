from rest_framework import serializers
from users.infrastructure.serializers import MototaxistaSerializer, UsuarioSerializer

from .models import SolicitudViaje, Viaje


class SolicitudViajeSerializer(serializers.ModelSerializer):
    class Meta:
        model = SolicitudViaje
        fields = ['id', 'pasajero', 'origen', 'destino', 'tarifa_propuesta', 'estado']
        read_only_fields = ['estado']


class ViajeSerializer(serializers.ModelSerializer):
    pasajero = UsuarioSerializer(read_only=True)
    conductor = MototaxistaSerializer(read_only=True)

    class Meta:
        model = Viaje
        fields = ['id', 'solicitud', 'pasajero', 'conductor', 'tarifa_final', 'estado']
