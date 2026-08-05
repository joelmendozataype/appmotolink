from rest_framework import serializers

from negotiation.domain.entities import EstadoOferta, TipoOferta
from users.infrastructure.serializers import MototaxistaSerializer


class OfertaSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    solicitud = serializers.CharField(source='solicitud_id', read_only=True)
    conductor = MototaxistaSerializer(read_only=True)
    tarifa = serializers.DecimalField(max_digits=8, decimal_places=2, read_only=True)
    tipo = serializers.ChoiceField(choices=TipoOferta.valores(), read_only=True)
    estado = serializers.ChoiceField(choices=EstadoOferta.valores(), read_only=True)
    fecha = serializers.DateTimeField(read_only=True)
