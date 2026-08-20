"""Qué es un origen y un destino válidos.

Vive en el dominio, no en el serializer, por lo mismo que las
validaciones de usuarios: la regla es del negocio y debe cumplirse venga
la solicitud de donde venga.

El caso que la trajo aquí: el campo aceptaba «.,mnhfg_#» y «SX:::S:»,
que se guardaban tal cual y luego aparecían en la lista del mototaxista
sin decirle a dónde tenía que ir.
"""
import re
from decimal import Decimal, InvalidOperation

# Un lugar empieza por letra o número y admite lo que sale en las
# direcciones de por aquí: «Jr. Grau 123», «Av. Los Andes», «Plaza de
# Pampas». Quedan fuera los signos que solo aparecen al teclear al azar.
_LUGAR = re.compile(
    r"^[A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9][A-Za-zÁÉÍÓÚÜÑáéíóúüñ0-9 .,'\-/]*$",
)

# Lo que escribe el botón de GPS de la app: «-12.39031, -74.85911».
# Sin esta excepción se rechazaría lo que la propia aplicación rellena.
_COORDENADAS = re.compile(r'^-?\d{1,3}\.\d+,\s*-?\d{1,3}\.\d+$')

_LETRA = re.compile(r'[A-Za-zÁÉÍÓÚÜÑáéíóúüñ]')

LONGITUD_MINIMA = 3


# Un viaje gratis no es una tarifa: antes se admitía desde cero y una
# solicitud de S/ 0 llegaba igual a los mototaxistas.
TARIFA_MINIMA = Decimal('1')
TARIFA_MAXIMA = Decimal('9999.99')


class TarifaInvalidaError(ValueError):
    """El monto no es un importe en soles válido."""


def validar_tarifa(valor):
    """Devuelve la tarifa como Decimal de dos decimales, o lanza.

    Admite enteros y decimales desde S/ 1. Rechaza el cero, los
    negativos, el texto y más de dos decimales, que en soles no
    significan nada.

    La contraoferta del conductor no pasaba por ningún serializer —el
    valor se leía directo del cuerpo de la petición—, así que hasta un
    importe negativo se habría guardado.
    """
    if valor is None or (isinstance(valor, str) and not valor.strip()):
        raise TarifaInvalidaError('Ingresa una tarifa.')
    try:
        tarifa = Decimal(str(valor).strip())
    except InvalidOperation as error:
        raise TarifaInvalidaError('La tarifa debe ser un número.') from error

    if not tarifa.is_finite():
        raise TarifaInvalidaError('La tarifa debe ser un número.')
    if tarifa < TARIFA_MINIMA:
        raise TarifaInvalidaError(f'La tarifa mínima es S/ {TARIFA_MINIMA}.')
    if tarifa > TARIFA_MAXIMA:
        raise TarifaInvalidaError(f'La tarifa no puede pasar de S/ {TARIFA_MAXIMA}.')
    if -tarifa.as_tuple().exponent > 2:
        raise TarifaInvalidaError('Como mucho dos decimales.')
    return tarifa


class LugarInvalidoError(ValueError):
    """El origen o el destino no nombran ningún sitio."""


def validar_lugar(valor, campo):
    """Devuelve el lugar recortado, o lanza LugarInvalidoError.

    `campo` es 'el origen' o 'el destino', para nombrarlo en el mensaje.
    """
    lugar = (valor or '').strip()
    if not lugar:
        raise LugarInvalidoError(f'Ingresa {campo}.')
    if _COORDENADAS.match(lugar):
        return lugar
    if len(lugar) < LONGITUD_MINIMA:
        raise LugarInvalidoError('Escribe al menos 3 caracteres.')
    if not _LUGAR.match(lugar):
        raise LugarInvalidoError('Usa solo letras, números y espacios.')
    # '123' o '...' pasarían el filtro anterior sin nombrar ningún sitio.
    if len(_LETRA.findall(lugar)) < 3:
        raise LugarInvalidoError('Escribe el nombre del lugar.')
    return lugar
