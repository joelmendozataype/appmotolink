"""Composición de dependencias.

Punto único donde se decide qué implementación concreta de repositorio
usa la aplicación. Las vistas y los casos de uso piden repositorios aquí
y nunca importan `firestore_repositories` directamente, de modo que
cambiar de almacén es cambiar este archivo.
"""
from negotiation.infrastructure.firestore_repositories import FirestoreOfertaRepository
from ratings.infrastructure.firestore_repositories import (
    FirestoreCalificacionRepository,
)
from trips.infrastructure.firestore_repositories import (
    FirestoreSolicitudViajeRepository,
    FirestoreViajeRepository,
)
from users.infrastructure.firestore_repositories import (
    FirestoreMototaxistaRepository,
    FirestoreUsuarioRepository,
)


def usuario_repo():
    return FirestoreUsuarioRepository()


def mototaxista_repo():
    return FirestoreMototaxistaRepository()


def solicitud_repo():
    return FirestoreSolicitudViajeRepository()


def viaje_repo():
    return FirestoreViajeRepository()


def oferta_repo():
    return FirestoreOfertaRepository()


def calificacion_repo():
    return FirestoreCalificacionRepository()
