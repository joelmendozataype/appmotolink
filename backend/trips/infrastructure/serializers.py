"""Serializers de solicitudes y viajes.

`pasajero` y `solicitud` siguen saliendo como el id plano (igual que la
PrimaryKeyRelatedField del ModelSerializer anterior); `source` los
conecta con los campos `*_id` de las entidades.
"""
from rest_framework import serializers

from trips.domain.entities import EstadoSolicitud, EstadoViaje
from trips.domain.validaciones import (
    LugarInvalidoError,
    TarifaInvalidaError,
    validar_lugar,
    validar_tarifa,
)
from users.infrastructure.serializers import MototaxistaSerializer, UsuarioSerializer


def _validar_lugar(valor, campo):
    """Traduce la regla del dominio al error que entiende DRF."""
    try:
        return validar_lugar(valor, campo)
    except LugarInvalidoError as error:
        raise serializers.ValidationError(str(error))


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
    # Solo tiene sentido para un mototaxista mirando el listado: le dice
    # si esa solicitud ya la respondió. Sin esto, todas se veían iguales y
    # al pulsar recibía un 409 "Ya respondiste a esta solicitud".
    ya_respondida = serializers.SerializerMethodField()

    def validate_tarifa_propuesta(self, valor):
        try:
            return validar_tarifa(valor)
        except TarifaInvalidaError as error:
            raise serializers.ValidationError(str(error))

    def validate_origen(self, valor):
        return _validar_lugar(valor, 'el origen')

    def validate_destino(self, valor):
        return _validar_lugar(valor, 'el destino')

    def get_ya_respondida(self, solicitud):
        respondidas = self.context.get('respondidas')
        if respondidas is None:
            return None
        return str(solicitud.id) in respondidas


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
