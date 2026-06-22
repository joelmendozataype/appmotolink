import uuid

from django.db import models

from trips.infrastructure.models import SolicitudViaje
from users.infrastructure.models import Mototaxista


class TipoOferta(models.TextChoices):
    ACEPTACION = 'aceptacion', 'Aceptación'
    CONTRAOFERTA = 'contraoferta', 'Contraoferta'
    RECHAZO = 'rechazo', 'Rechazo'


class EstadoOferta(models.TextChoices):
    PENDIENTE = 'pendiente', 'Pendiente'
    ACEPTADA = 'aceptada', 'Aceptada'
    RECHAZADA = 'rechazada', 'Rechazada'


class Oferta(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    solicitud = models.ForeignKey(
        SolicitudViaje, on_delete=models.CASCADE, related_name='ofertas',
    )
    conductor = models.ForeignKey(
        Mototaxista, on_delete=models.CASCADE, related_name='ofertas',
    )
    tarifa = models.DecimalField(max_digits=8, decimal_places=2)
    tipo = models.CharField(max_length=20, choices=TipoOferta.choices)
    estado = models.CharField(
        max_length=20, choices=EstadoOferta.choices, default=EstadoOferta.PENDIENTE,
    )
    fecha = models.DateTimeField(auto_now_add=True)

    class Meta:
        constraints = [
            models.UniqueConstraint(
                fields=['solicitud', 'conductor'], name='un_conductor_por_solicitud',
            ),
        ]

    def __str__(self):
        return f'Oferta {self.id} - {self.tarifa} ({self.estado})'
