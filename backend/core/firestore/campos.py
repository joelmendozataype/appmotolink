"""Conversión entre tipos de dominio y tipos que Firestore sabe guardar.

Firestore no tiene DECIMAL: los importes se guardan como float y se
reconstruyen como Decimal al leer, para que la aritmética de tarifas
siga siendo exacta en el dominio y en la respuesta JSON.
"""
import uuid
from datetime import datetime, timezone
from decimal import Decimal


def nuevo_id():
    return str(uuid.uuid4())


def a_texto_id(valor):
    """Normaliza un id (UUID, str con o sin guiones) a str canónico."""
    if valor is None:
        return None
    if isinstance(valor, uuid.UUID):
        return str(valor)
    return str(valor)


def a_decimal(valor, defecto='0'):
    if valor is None:
        return Decimal(defecto)
    if isinstance(valor, Decimal):
        return valor
    # str() antes de Decimal evita arrastrar el ruido binario del float.
    return Decimal(str(valor))


def a_float(valor):
    return float(a_decimal(valor))


def ahora():
    return datetime.now(timezone.utc)


def a_datetime(valor):
    """Firestore devuelve DatetimeWithNanoseconds; el fake, datetime o str."""
    if valor is None:
        return None
    if isinstance(valor, datetime):
        return valor
    return datetime.fromisoformat(str(valor))
