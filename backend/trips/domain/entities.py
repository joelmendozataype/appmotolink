"""Entidades de solicitudes y viajes.

`pasajero_id` / `conductor_id` / `solicitud_id` son la referencia real
guardada en Firestore; `pasajero` / `conductor` / `solicitud` son la
entidad ya hidratada que rellenan los repositorios cuando hace falta
(el equivalente al select_related del ORM).
"""
from dataclasses import dataclass, field
from datetime import datetime
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
    creado_en: datetime | None = None
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
    creado_en: datetime | None = None
    finalizado_en: datetime | None = None
    solicitud: SolicitudViaje | None = None
    pasajero: object | None = None
    conductor: object | None = None

    @property
    def duracion_minutos(self):
        """Minutos entre la asignación y el cierre del viaje.

        Es None mientras el viaje siga en curso, y también en los viajes
        migrados desde SQLite: aquella base no guardaba fechas, así que no
        hay forma de reconstruirlas. Se distingue "todavía no terminó" de
        "no se sabe" mirando el estado.
        """
        if self.creado_en is None or self.finalizado_en is None:
            return None
        return round((self.finalizado_en - self.creado_en).total_seconds() / 60)

    def __str__(self):
        return f'Viaje {self.id} ({self.estado})'
