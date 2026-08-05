from abc import ABC, abstractmethod


class OfertaNoEncontradaError(Exception):
    """No existe una oferta con ese id."""


class OfertaRepository(ABC):
    @abstractmethod
    def crear(self, *, solicitud, conductor, tarifa, tipo):
        ...

    @abstractmethod
    def obtener_por_id(self, oferta_id):
        ...

    @abstractmethod
    def listar_por_solicitud(self, solicitud_id, *, solo_pendientes=True):
        ...

    @abstractmethod
    def listar_pendientes(self):
        ...

    @abstractmethod
    def buscar_de_conductor(self, solicitud_id, conductor_id):
        ...

    @abstractmethod
    def guardar(self, oferta):
        ...

    @abstractmethod
    def aceptar_si_pendiente(self, oferta_id):
        """Marca la oferta como aceptada solo si sigue pendiente, de forma
        atómica. Devuelve True si el cambio se aplicó.

        Impide que dos selecciones concurrentes acepten la misma oferta.
        """

    @abstractmethod
    def rechazar_otras(self, solicitud_id, oferta_ganadora_id):
        ...
