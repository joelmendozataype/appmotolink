"""Implementación en memoria del puerto `DocumentStore`.

La usan los tests y `MOTOLINK_DB_BACKEND=memory`. Es deliberadamente
simple, pero respeta las dos garantías de las que depende el dominio:
`create()` falla si el id ya existe, y `compare_and_set()` es atómico
respecto de otros hilos.
"""
import copy
import threading

from core.firestore.port import DocumentoYaExisteError, DocumentStore


class InMemoryDocumentStore(DocumentStore):
    def __init__(self):
        self._datos = {}
        self._lock = threading.RLock()

    def _coleccion(self, coleccion):
        return self._datos.setdefault(coleccion, {})

    def get(self, coleccion, doc_id):
        with self._lock:
            documento = self._coleccion(coleccion).get(str(doc_id))
            return copy.deepcopy(documento) if documento is not None else None

    def set(self, coleccion, doc_id, datos):
        with self._lock:
            self._coleccion(coleccion)[str(doc_id)] = copy.deepcopy(datos)

    def create(self, coleccion, doc_id, datos):
        with self._lock:
            documentos = self._coleccion(coleccion)
            if str(doc_id) in documentos:
                raise DocumentoYaExisteError(f'{coleccion}/{doc_id}')
            documentos[str(doc_id)] = copy.deepcopy(datos)

    def update(self, coleccion, doc_id, cambios):
        with self._lock:
            documentos = self._coleccion(coleccion)
            documento = documentos.get(str(doc_id))
            if documento is None:
                raise KeyError(f'{coleccion}/{doc_id}')
            documento.update(copy.deepcopy(cambios))

    def delete(self, coleccion, doc_id):
        with self._lock:
            self._coleccion(coleccion).pop(str(doc_id), None)

    def query(self, coleccion, filtros=(), limite=None):
        with self._lock:
            resultado = []
            for doc_id, documento in self._coleccion(coleccion).items():
                if all(filtro.evalua(documento) for filtro in filtros):
                    resultado.append((doc_id, copy.deepcopy(documento)))
                    if limite is not None and len(resultado) >= limite:
                        break
            return resultado

    def compare_and_set(self, coleccion, doc_id, campo, esperado, cambios):
        aceptables = esperado if isinstance(esperado, (list, tuple, set)) else (esperado,)
        with self._lock:
            documento = self._coleccion(coleccion).get(str(doc_id))
            if documento is None or documento.get(campo) not in aceptables:
                return False
            documento.update(copy.deepcopy(cambios))
            return True

    def limpiar(self):
        with self._lock:
            self._datos.clear()
