import uuid

from django.contrib.auth.hashers import check_password, make_password
from django.db import models


class RolUsuario(models.TextChoices):
    PASAJERO = 'pasajero', 'Pasajero'
    MOTOTAXISTA = 'mototaxista', 'Mototaxista'
    ADMINISTRADOR = 'administrador', 'Administrador'


class Usuario(models.Model):
    id = models.UUIDField(primary_key=True, default=uuid.uuid4, editable=False)
    nombre = models.CharField(max_length=150)
    correo = models.EmailField(unique=True)
    contrasena = models.CharField(max_length=255)
    rol = models.CharField(max_length=20, choices=RolUsuario.choices)
    is_active = models.BooleanField(default=True)

    def set_password(self, raw_password):
        self.contrasena = make_password(raw_password)

    def check_password(self, raw_password):
        return check_password(raw_password, self.contrasena)

    @property
    def is_authenticated(self):
        return True

    @property
    def is_anonymous(self):
        return False

    def __str__(self):
        return f'{self.nombre} ({self.rol})'


class Mototaxista(models.Model):
    usuario = models.OneToOneField(
        Usuario, on_delete=models.CASCADE, primary_key=True, related_name='mototaxista',
    )
    licencia = models.CharField(max_length=50)
    placa = models.CharField(max_length=20)
    marca_vehiculo = models.CharField(max_length=50)
    modelo_vehiculo = models.CharField(max_length=50)

    def __str__(self):
        return f'{self.usuario.nombre} - {self.placa}'
