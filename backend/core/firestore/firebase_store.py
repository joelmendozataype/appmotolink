"""Implementación real del puerto `DocumentStore` sobre Cloud Firestore.

Este es el único archivo del proyecto que importa el SDK de Firebase.
Si mañana se cambia de proveedor, se reemplaza solo este archivo.
"""
import os
import threading

from core.firestore.port import DocumentoYaExisteError, DocumentStore

_lock = threading.Lock()
_cliente = None


def _inicializar_app():
    """Inicializa firebase_admin una sola vez por proceso.

    La credencial se resuelve en este orden:

    1. FIREBASE_CREDENTIALS_FILE: ruta al JSON de cuenta de servicio.
    2. GOOGLE_APPLICATION_CREDENTIALS: la variable estándar de Google.
    3. Credenciales por defecto del entorno (Cloud Run, GCE, gcloud auth).

    Nunca se lee la credencial desde el repositorio: es un secreto real
    (a diferencia de google-services.json, que es config de cliente).
    """
    import firebase_admin
    from firebase_admin import credentials

    if firebase_admin._apps:
        return firebase_admin.get_app()

    ruta = os.environ.get('FIREBASE_CREDENTIALS_FILE')
    project_id = os.environ.get('FIREBASE_PROJECT_ID')
    opciones = {'projectId': project_id} if project_id else None

    if ruta:
        if not os.path.exists(ruta):
            raise RuntimeError(
                f'FIREBASE_CREDENTIALS_FILE apunta a un archivo inexistente: {ruta}. '
                'Descarga la clave de cuenta de servicio desde la consola de Firebase '
                '(Configuración del proyecto > Cuentas de servicio > Generar nueva clave).',
            )
        return firebase_admin.initialize_app(credentials.Certificate(ruta), opciones)

    return firebase_admin.initialize_app(options=opciones)


def get_cliente():
    global _cliente
    with _lock:
        if _cliente is None:
            from firebase_admin import firestore

            _cliente = firestore.client(_inicializar_app())
        return _cliente


class FirestoreDocumentStore(DocumentStore):
    def __init__(self, cliente=None):
        self._cliente_inyectado = cliente

    @property
    def cliente(self):
        return self._cliente_inyectado or get_cliente()

    def _ref(self, coleccion, doc_id):
        return self.cliente.collection(coleccion).document(str(doc_id))

    def get(self, coleccion, doc_id):
        snapshot = self._ref(coleccion, doc_id).get()
        return snapshot.to_dict() if snapshot.exists else None

    def set(self, coleccion, doc_id, datos):
        self._ref(coleccion, doc_id).set(datos)

    def create(self, coleccion, doc_id, datos):
        from google.api_core import exceptions as google_exceptions

        try:
            # create() falla si el documento ya existe: así se replica la
            # UNIQUE constraint que antes daba SQLite.
            self._ref(coleccion, doc_id).create(datos)
        except google_exceptions.AlreadyExists as error:
            raise DocumentoYaExisteError(f'{coleccion}/{doc_id}') from error

    def update(self, coleccion, doc_id, cambios):
        self._ref(coleccion, doc_id).update(cambios)

    def delete(self, coleccion, doc_id):
        self._ref(coleccion, doc_id).delete()

    def query(self, coleccion, filtros=(), limite=None):
        from google.cloud.firestore_v1.base_query import FieldFilter

        consulta = self.cliente.collection(coleccion)
        for filtro in filtros:
            consulta = consulta.where(
                filter=FieldFilter(filtro.campo, filtro.operador, filtro.valor),
            )
        if limite is not None:
            consulta = consulta.limit(limite)
        return [(snapshot.id, snapshot.to_dict()) for snapshot in consulta.stream()]

    def compare_and_set(self, coleccion, doc_id, campo, esperado, cambios):
        from firebase_admin import firestore

        aceptables = esperado if isinstance(esperado, (list, tuple, set)) else (esperado,)
        ref = self._ref(coleccion, doc_id)

        @firestore.firestore.transactional
        def _transaccion(transaction):
            snapshot = ref.get(transaction=transaction)
            if not snapshot.exists:
                return False
            if snapshot.to_dict().get(campo) not in aceptables:
                return False
            transaction.update(ref, cambios)
            return True

        return _transaccion(self.cliente.transaction())
