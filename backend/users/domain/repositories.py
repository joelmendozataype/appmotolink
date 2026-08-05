from abc import ABC, abstractmethod


class UsuarioNoEncontradoError(Exception):
    """No existe un usuario con ese id o correo."""


class MototaxistaNoEncontradoError(Exception):
    """No existe un mototaxista con ese id de usuario."""


class CorreoDuplicadoError(Exception):
    """Ya hay un usuario registrado con ese correo."""


class UsuarioRepository(ABC):
    @abstractmethod
    def crear(self, usuario):
        ...

    @abstractmethod
    def obtener_por_id(self, usuario_id):
        ...

    @abstractmethod
    def buscar_por_correo(self, correo):
        ...

    @abstractmethod
    def listar(self, *, rol=None):
        ...

    @abstractmethod
    def guardar(self, usuario):
        ...

    @abstractmethod
    def eliminar(self, usuario_id):
        ...


class MototaxistaRepository(ABC):
    @abstractmethod
    def crear(self, mototaxista):
        ...

    @abstractmethod
    def obtener_por_id(self, usuario_id):
        ...

    @abstractmethod
    def listar(self):
        ...

    @abstractmethod
    def guardar(self, mototaxista):
        ...

    @abstractmethod
    def eliminar(self, usuario_id):
        ...
