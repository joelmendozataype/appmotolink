"""Entidad Calificación.

En SQLite el rango 1..5 quedaba a medias: el CHECK generado era
`puntuacion >= 0` y el 1..5 solo lo aplicaba el validador de Django.
Aquí el rango es parte de la entidad, así que se cumple siempre, venga
la escritura de donde venga.
"""
from dataclasses import dataclass, field
from datetime import datetime

from core.firestore.campos import nuevo_id

PUNTUACION_MINIMA = 1
PUNTUACION_MAXIMA = 5


class PuntuacionInvalidaError(ValueError):
    """La puntuación cae fuera del rango 1..5."""


@dataclass
class Calificacion:
    viaje_id: str
    puntuacion: int
    comentario: str = ''
    fecha: datetime | None = None
    id: str = field(default_factory=nuevo_id)

    def __post_init__(self):
        self.puntuacion = int(self.puntuacion)
        if not PUNTUACION_MINIMA <= self.puntuacion <= PUNTUACION_MAXIMA:
            raise PuntuacionInvalidaError(
                f'La puntuación debe estar entre {PUNTUACION_MINIMA} y '
                f'{PUNTUACION_MAXIMA}; llegó {self.puntuacion}.',
            )

    def __str__(self):
        return f'Calificación {self.puntuacion}/5 — viaje {self.viaje_id}'
