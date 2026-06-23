from django.test import TestCase
from rest_framework.test import APIClient

from trips.infrastructure.models import SolicitudViaje
from users.infrastructure.models import Mototaxista, RolUsuario, Usuario


class ConcurrenciaNegociacionTests(TestCase):
    """Casos donde dos conductores compiten por la misma solicitud, y
    entradas inválidas/inexistentes que deben fallar de forma controlada
    en vez de romper el servidor."""

    def setUp(self):
        self.client = APIClient()
        self.pasajero = Usuario.objects.create(
            nombre='Pasajero Test', correo='pasajero.conc@motolink.com',
            rol=RolUsuario.PASAJERO,
        )
        self.solicitud = SolicitudViaje.objects.create(
            pasajero=self.pasajero, origen='A', destino='B',
            tarifa_propuesta=10.0, estado='pendiente',
        )

        usuario_a = Usuario.objects.create(
            nombre='Conductor A', correo='conductor.a@motolink.com',
            rol=RolUsuario.MOTOTAXISTA,
        )
        self.conductor_a = Mototaxista.objects.create(
            usuario=usuario_a, licencia='LIC-A', placa='AAA-001',
            marca_vehiculo='Honda', modelo_vehiculo='Wave',
        )
        usuario_b = Usuario.objects.create(
            nombre='Conductor B', correo='conductor.b@motolink.com',
            rol=RolUsuario.MOTOTAXISTA,
        )
        self.conductor_b = Mototaxista.objects.create(
            usuario=usuario_b, licencia='LIC-B', placa='BBB-002',
            marca_vehiculo='Yamaha', modelo_vehiculo='Crypton',
        )

    def test_dos_conductores_responden_y_solo_uno_es_seleccionable(self):
        """Ambos conductores pueden responder a la misma solicitud abierta
        (ambos compiten); el pasajero solo puede seleccionar una vez."""
        respuesta_a = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {'conductor_id': str(self.conductor_a.usuario_id)}, format='json',
        )
        self.assertEqual(respuesta_a.status_code, 201)

        respuesta_b = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/contraofertar/',
            {'conductor_id': str(self.conductor_b.usuario_id), 'tarifa': 8},
            format='json',
        )
        self.assertEqual(respuesta_b.status_code, 201)

        oferta_a_id = respuesta_a.data['id']
        oferta_b_id = respuesta_b.data['id']

        # El pasajero selecciona la oferta de A: el viaje queda asignado.
        seleccion = self.client.post(f'/api/ofertas/{oferta_a_id}/seleccionar/')
        self.assertEqual(seleccion.status_code, 201)

        # La oferta de B ya no puede seleccionarse: la solicitud quedó cerrada.
        intento_tardio = self.client.post(
            f'/api/ofertas/{oferta_b_id}/seleccionar/',
        )
        self.assertEqual(intento_tardio.status_code, 409)

    def test_seleccionar_oferta_inexistente_devuelve_404_no_500(self):
        """Bug real encontrado por esta prueba: seleccionar un UUID de
        oferta que no existe lanzaba un 500 sin manejar (el repositorio
        usa `.get()`, que levanta DoesNotExist). Corregido para devolver
        404 controlado — ver negotiation/presentation/views.py."""
        uuid_inexistente = '00000000-0000-0000-0000-000000000000'
        respuesta = self.client.post(
            f'/api/ofertas/{uuid_inexistente}/seleccionar/',
        )
        self.assertEqual(respuesta.status_code, 404)
        self.assertIn('detail', respuesta.data)

    def test_aceptar_con_solicitud_inexistente_devuelve_404_no_500(self):
        uuid_inexistente = '00000000-0000-0000-0000-000000000000'
        respuesta = self.client.post(
            f'/api/solicitudes-viaje/{uuid_inexistente}/aceptar/',
            {'conductor_id': str(self.conductor_a.usuario_id)}, format='json',
        )
        self.assertEqual(respuesta.status_code, 404)
