"""Qué es un nombre y un correo válidos, para cualquier rol.

Vive en el dominio y no en el serializer porque no es una regla del
transporte HTTP, sino del negocio: da igual si la cuenta llega desde la
app, desde la API o desde un comando del servidor.

Ese fue justamente el hueco que lo trajo aquí. La regla estaba escrita en
`infrastructure/serializers.py`, así que la cumplían el registro de
pasajero y el de mototaxista —que anida el mismo serializer—, pero no
`manage.py crear_administrador`, el único camino por el que se dan de
alta los administradores. Los tres roles deben cumplirla.
"""
import re

# Letras, tildes y eñe, con espacios entre palabras. Se admiten los
# acentos porque son letras corrientes en los nombres de aquí (José,
# Ñahui, Muñoz). No se admiten cifras ni signos, ni espacios sueltos al
# principio o al final.
_NOMBRE = re.compile(r'^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+( [A-Za-zÁÉÍÓÚÜÑáéíóúüñ]+)*$')

# Algo@algo.algo. No cubre el estándar completo de direcciones, que admite
# rarezas que nadie escribe: basta con atajar lo que se teclea por error.
_CORREO = re.compile(r'^[A-Za-z0-9._%+-]+@[A-Za-z0-9-]+(\.[A-Za-z0-9-]+)+$')

LONGITUD_MINIMA_NOMBRE = 2


class DatoInvalidoError(ValueError):
    """Un campo de la cuenta no cumple su formato."""


def validar_nombre(valor):
    """Devuelve el nombre ya recortado, o lanza DatoInvalidoError."""
    nombre = (valor or '').strip()
    if not nombre:
        raise DatoInvalidoError('Ingresa tu nombre.')
    if len(nombre) < LONGITUD_MINIMA_NOMBRE:
        raise DatoInvalidoError('Escribe tu nombre completo.')
    # Mensaje aparte para el error más frecuente, que es teclear cifras.
    if any(c.isdigit() for c in nombre):
        raise DatoInvalidoError('El nombre no puede tener números.')
    if not _NOMBRE.match(nombre):
        raise DatoInvalidoError('Usa solo letras y espacios.')
    return nombre


def validar_correo(valor):
    """Devuelve el correo recortado, o lanza DatoInvalidoError."""
    correo = (valor or '').strip()
    if not correo:
        raise DatoInvalidoError('Ingresa tu correo.')
    if '@' not in correo:
        raise DatoInvalidoError('Falta el @ (ejemplo: tucorreo@gmail.com).')
    if not _CORREO.match(correo):
        raise DatoInvalidoError('Correo no válido (ejemplo: tucorreo@gmail.com).')
    return correo
