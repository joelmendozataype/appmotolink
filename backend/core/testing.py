"""Utilidades de test para la persistencia documental.

`FirestoreTestCase` hereda de SimpleTestCase, que prohíbe el acceso a la
base SQL: si algún día una vista vuelve a colarse al ORM, los tests
fallan en vez de pasar en silencio.

Cada test arranca con un almacén en memoria vacío, igual que antes cada
test arrancaba con una base de datos de test recién creada.
"""
from django.conf import settings
from django.test import SimpleTestCase, override_settings

from core.authentication import SESSION_KEY
from core.firestore import set_store
from core.firestore.memory import InMemoryDocumentStore
from core.di import (
    calificacion_repo,
    mototaxista_repo,
    oferta_repo,
    solicitud_repo,
    usuario_repo,
    viaje_repo,
)
from users.domain.entities import Mototaxista, RolUsuario, Usuario


@override_settings(
    # PBKDF2 se lleva casi todo el tiempo de la suite y aquí no aporta
    # nada: el algoritmo real se sigue usando fuera de los tests, y
    # check_password lo deduce del prefijo del hash de todos modos.
    PASSWORD_HASHERS=['django.contrib.auth.hashers.MD5PasswordHasher'],
)
class FirestoreTestCase(SimpleTestCase):
    def setUp(self):
        super().setUp()
        self.store = InMemoryDocumentStore()
        set_store(self.store)

    # --- fixtures habituales ------------------------------------------

    def crear_usuario(self, *, nombre, correo, rol=RolUsuario.PASAJERO,
                      contrasena=None):
        usuario = Usuario(nombre=nombre, correo=correo, rol=rol)
        if contrasena:
            usuario.set_password(contrasena)
        return usuario_repo().crear(usuario)

    # --- sesión ---------------------------------------------------------

    def autenticar(self, usuario, cliente=None):
        """Deja al cliente con la sesión de `usuario` iniciada.

        Desde la revisión de seguridad casi toda la API exige sesión, así
        que los tests tienen que autenticarse igual que la app. Se escribe
        la sesión directamente en vez de pasar por /login para no depender
        de conocer la contraseña de cada fixture.
        """
        cliente = cliente or self.client
        sesion = cliente.session
        sesion[SESSION_KEY] = str(usuario.id)
        sesion.save()
        # Con el backend de cookies firmadas hay que devolverle la cookie
        # al cliente a mano: no hay tabla de sesiones que consultar.
        cliente.cookies[settings.SESSION_COOKIE_NAME] = sesion.session_key
        return usuario

    def cliente_de(self, usuario):
        """Un APIClient nuevo con la sesión de `usuario` ya iniciada.

        Permite tener pasajero y conductor a la vez en el mismo test, que
        es como ocurre de verdad: dos dispositivos distintos.
        """
        from rest_framework.test import APIClient

        cliente = APIClient()
        self.autenticar(usuario, cliente)
        return cliente

    def crear_mototaxista(self, *, nombre, correo, licencia='LIC-000',
                          placa='XXX-000', marca='Honda', modelo='Wave'):
        usuario = self.crear_usuario(
            nombre=nombre, correo=correo, rol=RolUsuario.MOTOTAXISTA,
        )
        return mototaxista_repo().crear(Mototaxista(
            usuario_id=usuario.id,
            licencia=licencia,
            placa=placa,
            marca_vehiculo=marca,
            modelo_vehiculo=modelo,
            usuario=usuario,
        ))

    def crear_solicitud(self, *, pasajero, origen='A', destino='B', tarifa=10):
        return solicitud_repo().crear(
            pasajero=pasajero, origen=origen, destino=destino,
            tarifa_propuesta=tarifa,
        )

    # --- repositorios -------------------------------------------------

    @property
    def usuarios(self):
        return usuario_repo()

    @property
    def mototaxistas(self):
        return mototaxista_repo()

    @property
    def solicitudes(self):
        return solicitud_repo()

    @property
    def viajes(self):
        return viaje_repo()

    @property
    def ofertas(self):
        return oferta_repo()

    @property
    def calificaciones(self):
        return calificacion_repo()
