"""Compatibilidad: `negotiation.models` reexporta las entidades de dominio.

Ya no hay modelos de Django en esta app; la persistencia es Firestore
(ver negotiation/infrastructure/firestore_repositories.py).
"""
from negotiation.domain.entities import EstadoOferta, Oferta, TipoOferta

__all__ = ['Oferta', 'EstadoOferta', 'TipoOferta']
