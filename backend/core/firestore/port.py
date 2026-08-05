"""Puerto de persistencia documental.

Se expone deliberadamente una superficie mínima: solo las operaciones que
los repositorios de MotoLink necesitan. Cuanto más chica es esta interfaz,
más fiel puede ser la implementación en memoria que usan los tests.
"""
from abc import ABC, abstractmethod
from dataclasses import dataclass
from typing import Any


class DocumentoYaExisteError(Exception):
    """`create()` sobre un id que ya existe.

    Es el reemplazo directo de la UNIQUE constraint que SQLite aplicaba
    sobre (solicitud, conductor): en Firestore la unicidad se consigue
    derivando el id del documento de esa misma pareja de campos.
    """


@dataclass(frozen=True)
class Filtro:
    """Condición de consulta. Solo se soportan '==' e 'in', que es todo
    lo que necesitan las consultas de MotoLink."""

    campo: str
    operador: str
    valor: Any

    def __post_init__(self):
        if self.operador not in ('==', 'in'):
            raise ValueError(f'Operador no soportado: {self.operador}')

    def evalua(self, documento):
        actual = documento.get(self.campo)
        if self.operador == '==':
            return actual == self.valor
        return actual in self.valor


class DocumentStore(ABC):
    """Almacén de documentos agrupados en colecciones."""

    @abstractmethod
    def get(self, coleccion, doc_id):
        """Devuelve el documento como dict, o None si no existe."""

    @abstractmethod
    def set(self, coleccion, doc_id, datos):
        """Escribe el documento completo (crea o reemplaza)."""

    @abstractmethod
    def create(self, coleccion, doc_id, datos):
        """Escribe solo si el id está libre.

        Levanta DocumentoYaExisteError si el documento ya existe.
        """

    @abstractmethod
    def update(self, coleccion, doc_id, cambios):
        """Actualiza los campos indicados, dejando el resto intacto."""

    @abstractmethod
    def delete(self, coleccion, doc_id):
        """Borra el documento; no falla si no existía."""

    @abstractmethod
    def query(self, coleccion, filtros=(), limite=None):
        """Devuelve [(doc_id, datos)] de los documentos que cumplen todos
        los filtros. El orden no está garantizado."""

    @abstractmethod
    def compare_and_set(self, coleccion, doc_id, campo, esperado, cambios):
        """Actualiza `cambios` solo si `campo` vale `esperado`, de forma
        atómica. `esperado` puede ser un valor o una tupla/lista de
        valores aceptables. Devuelve True si el cambio se aplicó.

        Es la primitiva con la que se resuelven las carreras que antes
        cubría una transacción SQL: dos pasajeros no pueden cerrar la
        misma solicitud, ni dos selecciones aceptar la misma oferta.
        """

    def borrar_coleccion(self, coleccion):
        """Vacía una colección. Solo se usa en migración y tests."""
        for doc_id, _ in self.query(coleccion):
            self.delete(coleccion, doc_id)
