"""Entidad Oferta.

La UNIQUE constraint `un_conductor_por_solicitud` que aplicaba SQLite se
traslada al identificador del documento: `id_documento()` deriva el id de
la pareja (solicitud, conductor), de modo que un segundo intento del
mismo conductor choca contra un `create()` que ya existe.
"""
from dataclasses import dataclass, field
from datetime import datetime
from decimal import Decimal
from enum import StrEnum


class TipoOferta(StrEnum):
    ACEPTACION = 'aceptacion'
    CONTRAOFERTA = 'contraoferta'
    RECHAZO = 'rechazo'

    @classmethod
    def valores(cls):
        return [tipo.value for tipo in cls]


class EstadoOferta(StrEnum):
    PENDIENTE = 'pendiente'
    ACEPTADA = 'aceptada'
    RECHAZADA = 'rechazada'

    @classmethod
    def valores(cls):
        return [estado.value for estado in cls]


def id_documento(solicitud_id, conductor_id):
    """Id determinista: garantiza una sola oferta por (solicitud, conductor)."""
    return f'{solicitud_id}__{conductor_id}'


@dataclass
class Oferta:
    solicitud_id: str
    conductor_id: str
    tarifa: Decimal
    tipo: str
    estado: str = EstadoOferta.PENDIENTE
    fecha: datetime | None = None
    id: str = field(default='')
    solicitud: object | None = None
    conductor: object | None = None

    def __post_init__(self):
        if not self.id:
            self.id = id_documento(self.solicitud_id, self.conductor_id)

    def __str__(self):
        return f'Oferta {self.id} - {self.tarifa} ({self.estado})'
