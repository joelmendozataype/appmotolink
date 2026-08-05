from abc import ABC, abstractmethod


class CalificacionNoEncontradaError(Exception):
    """No existe una calificación con ese id."""


class ViajeYaCalificadoError(Exception):
    """El viaje ya tiene una calificación (era una relación 1:1)."""


class CalificacionRepository(ABC):
    @abstractmethod
    def crear(self, calificacion):
        ...

    @abstractmethod
    def obtener_por_id(self, calificacion_id):
        ...

    @abstractmethod
    def buscar_por_viaje(self, viaje_id):
        ...

    @abstractmethod
    def listar(self):
        ...
