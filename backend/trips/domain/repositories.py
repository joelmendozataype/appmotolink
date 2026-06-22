from abc import ABC, abstractmethod


class SolicitudViajeRepository(ABC):
    @abstractmethod
    def crear(self, *, pasajero, origen, destino, tarifa_propuesta):
        ...

    @abstractmethod
    def obtener_por_id(self, solicitud_id):
        ...

    @abstractmethod
    def listar_disponibles(self):
        ...

    @abstractmethod
    def guardar(self, solicitud):
        ...


class ViajeRepository(ABC):
    @abstractmethod
    def crear(self, *, solicitud, pasajero, conductor, tarifa_final):
        ...

    @abstractmethod
    def obtener_por_id(self, viaje_id):
        ...

    @abstractmethod
    def guardar(self, viaje):
        ...
