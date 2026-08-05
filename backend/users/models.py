"""Compatibilidad: `users.models` ahora reexporta las entidades de dominio.

Ya no hay modelos de Django en esta app; la persistencia es Firestore
(ver users/infrastructure/firestore_repositories.py).
"""
from users.domain.entities import Mototaxista, RolUsuario, Usuario

__all__ = ['Usuario', 'Mototaxista', 'RolUsuario']
