"""Serializers de solicitudes y viajes.

`pasajero` y `solicitud` siguen saliendo como el id plano (igual que la
PrimaryKeyRelatedField del ModelSerializer anterior); `source` los
conecta con los campos `*_id` de las entidades.
"""
from rest_framework import serializers

from trips.domain.entities import EstadoSolicitud, EstadoViaje
from users.infrastructure.serializers import MototaxistaSerializer, UsuarioSerializer


class SolicitudViajeSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    # Solo lectura: el pasajero sale de la sesión, no del cuerpo. La app
    # todavía lo envía y no pasa nada —se ignora—, pero exigirlo carecía
    # de sentido desde que dejó de usarse.
    pasajero = serializers.CharField(source='pasajero_id', read_only=True)
    origen = serializers.CharField(max_length=255)
    destino = serializers.CharField(max_length=255)
    tarifa_propuesta = serializers.DecimalField(max_digits=8, decimal_places=2)
    estado = serializers.ChoiceField(
        choices=EstadoSolicitud.valores(), read_only=True,
    )
    creado_en = serializers.DateTimeField(read_only=True)


class ViajeSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    solicitud = serializers.CharField(source='solicitud_id', read_only=True)
    pasajero = UsuarioSerializer(read_only=True)
    conductor = MototaxistaSerializer(read_only=True)
    tarifa_final = serializers.DecimalField(
        max_digits=8, decimal_places=2, read_only=True,
    )
    estado = serializers.ChoiceField(choices=EstadoViaje.valores(), read_only=True)
    creado_en = serializers.DateTimeField(read_only=True)
    finalizado_en = serializers.DateTimeField(read_only=True)
    # Se calcula en el servidor para que app y panel no dupliquen la
    # fórmula ni discrepen por zonas horarias.
    duracion_minutos = serializers.IntegerField(read_only=True)
