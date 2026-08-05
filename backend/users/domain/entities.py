"""Entidades de usuarios, sin dependencia del ORM de Django.

Sustituyen a los antiguos `models.Model`. Conservan a propósito los
mismos nombres de atributos (`usuario_id`, `is_active`, ...) para que
los casos de uso, el notificador y los tests no tengan que cambiar.

El hashing de contraseñas se sigue delegando en django.contrib.auth
.hashers: así los hashes migrados desde SQLite siguen validando y no
hay que forzar a nadie a cambiar su contraseña.
"""
from dataclasses import dataclass, field
from enum import StrEnum

from django.contrib.auth.hashers import check_password, make_password

from core.firestore.campos import nuevo_id


class RolUsuario(StrEnum):
    PASAJERO = 'pasajero'
    MOTOTAXISTA = 'mototaxista'
    ADMINISTRADOR = 'administrador'

    @classmethod
    def valores(cls):
        return [rol.value for rol in cls]


@dataclass
class Usuario:
    nombre: str
    correo: str
    rol: str
    id: str = field(default_factory=nuevo_id)
    contrasena: str = ''
    is_active: bool = True

    def set_password(self, raw_password):
        self.contrasena = make_password(raw_password)

    def check_password(self, raw_password):
        if not self.contrasena:
            return False
        return check_password(raw_password, self.contrasena)

    # DRF consulta estas dos propiedades en request.user para resolver
    # los permisos IsAuthenticated / AllowAny.
    @property
    def is_authenticated(self):
        return True

    @property
    def is_anonymous(self):
        return False

    def __str__(self):
        return f'{self.nombre} ({self.rol})'


@dataclass
class Mototaxista:
    usuario_id: str
    licencia: str
    placa: str
    marca_vehiculo: str
    modelo_vehiculo: str
    usuario: Usuario | None = None

    @property
    def id(self):
        """El mototaxista comparte identidad con su usuario (era una
        relación 1:1 con primary_key=True en SQLite)."""
        return self.usuario_id

    def __str__(self):
        nombre = self.usuario.nombre if self.usuario else self.usuario_id
        return f'{nombre} - {self.placa}'
