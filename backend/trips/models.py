"""Compatibilidad: `trips.models` ahora reexporta las entidades de dominio.

Ya no hay modelos de Django en esta app; la persistencia es Firestore
(ver trips/infrastructure/firestore_repositories.py).
"""
from trips.domain.entities import EstadoSolicitud, EstadoViaje, SolicitudViaje, Viaje

__all__ = ['SolicitudViaje', 'Viaje', 'EstadoSolicitud', 'EstadoViaje']
