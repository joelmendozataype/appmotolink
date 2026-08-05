from abc import ABC, abstractmethod


class SolicitudNoEncontradaError(Exception):
    """No existe una solicitud de viaje con ese id."""


class ViajeNoEncontradoError(Exception):
    """No existe un viaje con ese id."""


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
    def listar(self):
        ...

    @abstractmethod
    def guardar(self, solicitud):
        ...

    @abstractmethod
    def eliminar(self, solicitud_id):
        ...

    @abstractmethod
    def cerrar_si_disponible(self, solicitud_id, estados_aceptables, nuevo_estado):
        """Cambia el estado de forma atómica solo si el actual está entre
        `estados_aceptables`. Devuelve True si el cambio se aplicó.

        Reemplaza a la transacción SQL que impedía que dos selecciones
        concurrentes cerraran la misma solicitud.
        """


class ViajeRepository(ABC):
    @abstractmethod
    def crear(self, *, solicitud, pasajero, conductor, tarifa_final):
        ...

    @abstractmethod
    def obtener_por_id(self, viaje_id):
        ...

    @abstractmethod
    def listar(self):
        ...

    @abstractmethod
    def listar_por_usuario(self, usuario_id, *, estados=None):
        """Viajes donde el usuario participa como pasajero o como conductor."""

    @abstractmethod
    def guardar(self, viaje):
        ...

    @abstractmethod
    def eliminar(self, viaje_id):
        ...
