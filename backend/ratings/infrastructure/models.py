import uuid

from django.core.validators import MaxValueValidator, MinValueValidator
from django.db import models

from trips.infrastructure.models import Viaje


class Calificacion(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    viaje = models.OneToOneField(
        Viaje, on_delete=models.CASCADE, related_name='calificacion',
    )
    puntuacion = models.PositiveSmallIntegerField(
        validators=[MinValueValidator(1), MaxValueValidator(5)],
    )
    comentario = models.CharField(max_length=500, blank=True, default='')
    fecha = models.DateTimeField(auto_now_add=True)

    def __str__(self):
        return f'Calificación {self.puntuacion}/5 — viaje {self.viaje_id}'
