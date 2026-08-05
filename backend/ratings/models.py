"""Compatibilidad: `ratings.models` reexporta la entidad de dominio.

Ya no hay modelos de Django en esta app; la persistencia es Firestore
(ver ratings/infrastructure/firestore_repositories.py).
"""
from ratings.domain.entities import Calificacion

__all__ = ['Calificacion']
