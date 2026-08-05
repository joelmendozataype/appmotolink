"""Utilidades de test para la persistencia documental.

`FirestoreTestCase` hereda de SimpleTestCase, que prohíbe el acceso a la
base SQL: si algún día una vista vuelve a colarse al ORM, los tests
fallan en vez de pasar en silencio.

Cada test arranca con un almacén en memoria vacío, igual que antes cada
test arrancaba con una base de datos de test recién creada.
"""
from django.test import SimpleTestCase, override_settings

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
