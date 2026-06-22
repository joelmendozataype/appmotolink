import uuid

from django.db import models

from users.infrastructure.models import Usuario


class EstadoSolicitud(models.TextChoices):
    PENDIENTE = 'pendiente', 'Pendiente'
    EN_NEGOCIACION = 'enNegociacion', 'En negociación'
    ACEPTADA = 'aceptada', 'Aceptada'
    CANCELADA = 'cancelada', 'Cancelada'
    FINALIZADA = 'finalizada', 'Finalizada'


class EstadoViaje(models.TextChoices):
    ASIGNADO = 'asignado', 'Asignado'
    EN_CURSO = 'enCurso', 'En curso'
    FINALIZADO = 'finalizado', 'Finalizado'
    CANCELADO = 'cancelado', 'Cancelado'


class SolicitudViaje(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    pasajero = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, related_name='solicitudes_viaje',
    )
    origen = models.CharField(max_length=255)
    destino = models.CharField(max_length=255)
    tarifa_propuesta = models.DecimalField(max_digits=8, decimal_places=2)
    estado = models.CharField(
        max_length=20, choices=EstadoSolicitud.choices,
        default=EstadoSolicitud.PENDIENTE,
    )

    def __str__(self):
        return f'{self.origen} -> {self.destino} ({self.estado})'


class Viaje(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    solicitud = models.OneToOneField(
        SolicitudViaje, on_delete=models.CASCADE, related_name='viaje',
    )
    pasajero = models.ForeignKey(
        Usuario, on_delete=models.CASCADE, related_name='viajes_como_pasajero',
    )
    conductor = models.ForeignKey(
        'users.Mototaxista', on_delete=models.CASCADE, related_name='viajes_como_conductor',
    )
    tarifa_final = models.DecimalField(max_digits=8, decimal_places=2)
    estado = models.CharField(
        max_length=20, choices=EstadoViaje.choices, default=EstadoViaje.ASIGNADO,
    )

    def __str__(self):
        return f'Viaje {self.id} ({self.estado})'
