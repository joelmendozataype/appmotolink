"""Entidades de solicitudes y viajes.

`pasajero_id` / `conductor_id` / `solicitud_id` son la referencia real
guardada en Firestore; `pasajero` / `conductor` / `solicitud` son la
entidad ya hidratada que rellenan los repositorios cuando hace falta
(el equivalente al select_related del ORM).
"""
from dataclasses import dataclass, field
from decimal import Decimal
from enum import StrEnum

from core.firestore.campos import nuevo_id


class EstadoSolicitud(StrEnum):
    PENDIENTE = 'pendiente'
    EN_NEGOCIACION = 'enNegociacion'
    ACEPTADA = 'aceptada'
    CANCELADA = 'cancelada'
    FINALIZADA = 'finalizada'

    @classmethod
    def valores(cls):
        return [estado.value for estado in cls]


class EstadoViaje(StrEnum):
    ASIGNADO = 'asignado'
    EN_CURSO = 'enCurso'
    FINALIZADO = 'finalizado'
    CANCELADO = 'cancelado'

    @classmethod
    def valores(cls):
        return [estado.value for estado in cls]


@dataclass
class SolicitudViaje:
    pasajero_id: str
    origen: str
    destino: str
    tarifa_propuesta: Decimal
    estado: str = EstadoSolicitud.PENDIENTE
    id: str = field(default_factory=nuevo_id)
    pasajero: object | None = None

    def __str__(self):
        return f'{self.origen} -> {self.destino} ({self.estado})'


@dataclass
class Viaje:
    solicitud_id: str
    pasajero_id: str
    conductor_id: str
    tarifa_final: Decimal
    estado: str = EstadoViaje.ASIGNADO
    id: str = field(default_factory=nuevo_id)
    solicitud: SolicitudViaje | None = None
    pasajero: object | None = None
    conductor: object | None = None

    def __str__(self):
        return f'Viaje {self.id} ({self.estado})'
