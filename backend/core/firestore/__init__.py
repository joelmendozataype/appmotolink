"""Capa de acceso a documentos (Firestore).

Los repositorios NO hablan con `google.cloud.firestore` directamente:
dependen del puerto `DocumentStore` definido en `port.py`. Eso mantiene
el SDK de Firebase confinado a un solo archivo y permite correr toda la
suite de tests contra `InMemoryDocumentStore`, sin credenciales ni red.
"""
from core.firestore.port import (
    DocumentoYaExisteError,
    DocumentStore,
    Filtro,
)
from core.firestore.registry import get_store, reset_store, set_store

__all__ = [
    'DocumentStore',
    'DocumentoYaExisteError',
    'Filtro',
    'get_store',
    'set_store',
    'reset_store',
]
