"""Selección del `DocumentStore` activo.

El backend se elige con la variable de entorno MOTOLINK_DB_BACKEND:

    firestore  (default) -> Cloud Firestore vía firebase-admin
    memory               -> almacén en memoria (tests y demos offline)

Los tests llaman a `reset_store()` en setUp para arrancar con una base
limpia, igual que hacía Django con la BD de test.
"""
import os
import threading

_lock = threading.Lock()
_store = None


def _crear_store():
    backend = os.environ.get('MOTOLINK_DB_BACKEND', 'firestore').lower()
    if backend == 'memory':
        from core.firestore.memory import InMemoryDocumentStore

        return InMemoryDocumentStore()
    if backend == 'firestore':
        from core.firestore.firebase_store import FirestoreDocumentStore

        return FirestoreDocumentStore()
    raise RuntimeError(
        f"MOTOLINK_DB_BACKEND='{backend}' no es válido; usa 'firestore' o 'memory'.",
    )


def get_store():
    global _store
    with _lock:
        if _store is None:
            _store = _crear_store()
        return _store


def set_store(store):
    """Inyecta un almacén concreto (tests, script de migración)."""
    global _store
    with _lock:
        _store = store


def reset_store():
    """Descarta el almacén actual; el siguiente `get_store()` crea uno nuevo."""
    global _store
    with _lock:
        _store = None
