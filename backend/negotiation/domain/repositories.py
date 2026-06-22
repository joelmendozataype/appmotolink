from abc import ABC, abstractmethod


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
    def buscar_de_conductor(self, solicitud_id, conductor_id):
        ...

    @abstractmethod
    def guardar(self, oferta):
        ...

    @abstractmethod
    def rechazar_otras(self, solicitud_id, oferta_ganadora_id):
        ...
