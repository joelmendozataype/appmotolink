"""Permisos de MotoLink.

Regla de oro tras la revisión de seguridad: **el actor de una operación
sale siempre de `request.user`, nunca del cuerpo de la petición**. Antes,
`pasajero` y `conductor_id` llegaban en el JSON, así que cualquiera podía
pedir un viaje, ofertar o finalizar en nombre de otro.
"""
from rest_framework.permissions import SAFE_METHODS, BasePermission

from users.domain.entities import RolUsuario


def _rol(request):
    return getattr(getattr(request, 'user', None), 'rol', None)


class EsPasajero(BasePermission):
    message = 'Solo un pasajero puede realizar esta acción.'

    def has_permission(self, request, view):
        return _rol(request) == RolUsuario.PASAJERO


class EsMototaxista(BasePermission):
    message = 'Solo un mototaxista puede realizar esta acción.'

    def has_permission(self, request, view):
        return _rol(request) == RolUsuario.MOTOTAXISTA


class EsAdministrador(BasePermission):
    message = 'Solo un administrador puede realizar esta acción.'

    def has_permission(self, request, view):
        return _rol(request) == RolUsuario.ADMINISTRADOR


class EsAdministradorOSoloLectura(BasePermission):
    """Cualquiera autenticado puede leer; solo el administrador escribe."""

    message = 'Solo un administrador puede modificar este recurso.'

    def has_permission(self, request, view):
        if request.method in SAFE_METHODS:
            return True
        return _rol(request) == RolUsuario.ADMINISTRADOR


def es_administrador(usuario):
    return getattr(usuario, 'rol', None) == RolUsuario.ADMINISTRADOR


def participa_en_viaje(usuario, viaje):
    """El pasajero o el conductor del viaje. El administrador siempre pasa."""
    if es_administrador(usuario):
        return True
    usuario_id = str(getattr(usuario, 'id', ''))
    return usuario_id in (str(viaje.pasajero_id), str(viaje.conductor_id))
