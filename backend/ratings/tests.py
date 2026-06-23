from django.test import TestCase
from rest_framework.test import APIClient

from trips.infrastructure.models import SolicitudViaje, Viaje
from users.infrastructure.models import Mototaxista, RolUsuario, Usuario


class CalificacionTests(TestCase):
    """Cubre la persistencia de calificaciones contra el backend, incluyendo
    los límites de validación (1-5) y la restricción de una calificación
    por viaje."""

    def setUp(self):
        self.client = APIClient()
        pasajero = Usuario.objects.create(
            nombre='Pasajero Test', correo='pasajero.rating@motolink.com',
            rol=RolUsuario.PASAJERO,
        )
        usuario_conductor = Usuario.objects.create(
            nombre='Conductor Test', correo='conductor.rating@motolink.com',
            rol=RolUsuario.MOTOTAXISTA,
        )
        conductor = Mototaxista.objects.create(
            usuario=usuario_conductor, licencia='LIC-R', placa='RAT-001',
            marca_vehiculo='Honda', modelo_vehiculo='Wave',
        )
        solicitud = SolicitudViaje.objects.create(
            pasajero=pasajero, origen='A', destino='B',
            tarifa_propuesta=10.0, estado='aceptada',
        )
        self.viaje = Viaje.objects.create(
            solicitud=solicitud, pasajero=pasajero, conductor=conductor,
            tarifa_final=10.0, estado='finalizado',
        )

    def test_calificacion_valida_se_persiste(self):
        respuesta = self.client.post(
            '/api/calificaciones/',
            {'viaje': str(self.viaje.id), 'puntuacion': 4, 'comentario': 'Buen viaje'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        self.assertEqual(respuesta.data['puntuacion'], 4)

    def test_puntuacion_fuera_de_rango_es_rechazada(self):
        respuesta = self.client.post(
            '/api/calificaciones/',
            {'viaje': str(self.viaje.id), 'puntuacion': 6, 'comentario': ''},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 400)

    def test_no_se_puede_calificar_dos_veces_el_mismo_viaje(self):
        primera = self.client.post(
            '/api/calificaciones/',
            {'viaje': str(self.viaje.id), 'puntuacion': 5, 'comentario': ''},
            format='json',
        )
        self.assertEqual(primera.status_code, 201)

        segunda = self.client.post(
            '/api/calificaciones/',
            {'viaje': str(self.viaje.id), 'puntuacion': 2, 'comentario': ''},
            format='json',
        )
        self.assertEqual(segunda.status_code, 400)
