"""Recuperación de contraseña con código de un solo uso.

Se eligió un código de 6 dígitos en vez de un enlace porque la app es
móvil y no tiene enlaces profundos configurados: escribir seis números es
más simple que abrir el correo, pulsar un enlace y volver.

Decisiones de seguridad, y el porqué de cada una:

* El código se guarda **hasheado**, no en claro. Quien lea la base de
  datos no puede usarlo para entrar en una cuenta ajena.
* Caduca a los 15 minutos. Un código de 6 dígitos es adivinable a la
  fuerza si se le da tiempo suficiente.
* Es de un solo uso: se borra al canjearlo.
* Se limitan los intentos por código. Sin eso, seis dígitos son solo un
  millón de combinaciones.
* Pedir un código nuevo invalida el anterior.
"""
import secrets
from dataclasses import dataclass
from datetime import datetime, timedelta, timezone

from django.contrib.auth.hashers import check_password, make_password

DURACION = timedelta(minutes=15)
INTENTOS_MAXIMOS = 5
LONGITUD = 6


def generar_codigo():
    """Seis dígitos con generador criptográfico, no con random corriente."""
    return f'{secrets.randbelow(10 ** LONGITUD):0{LONGITUD}d}'


@dataclass
class CodigoRecuperacion:
    usuario_id: str
    codigo_hash: str
    expira_en: datetime
    intentos: int = 0

    @classmethod
    def nuevo(cls, usuario_id, codigo):
        return cls(
            usuario_id=str(usuario_id),
            codigo_hash=make_password(codigo),
            expira_en=datetime.now(timezone.utc) + DURACION,
        )

    @property
    def caducado(self):
        return datetime.now(timezone.utc) >= self.expira_en

    @property
    def agotado(self):
        return self.intentos >= INTENTOS_MAXIMOS

    def coincide(self, codigo):
        return check_password(codigo, self.codigo_hash)
