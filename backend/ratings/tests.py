from rest_framework.test import APIClient

from core.testing import FirestoreTestCase
from trips.domain.entities import EstadoSolicitud, EstadoViaje


class CalificacionTests(FirestoreTestCase):
    """Cubre la persistencia de calificaciones contra el backend, incluyendo
    los límites de validación (1-5) y la restricción de una calificación
    por viaje."""

    def setUp(self):
        super().setUp()
        self.client = APIClient()
        pasajero = self.crear_usuario(
            nombre='Pasajero Test', correo='pasajero.rating@motolink.com',
        )
        conductor = self.crear_mototaxista(
            nombre='Conductor Test', correo='conductor.rating@motolink.com',
            licencia='LIC-R', placa='RAT-001',
        )
        solicitud = self.crear_solicitud(pasajero=pasajero, tarifa=10)
        solicitud.estado = EstadoSolicitud.ACEPTADA
        self.solicitudes.guardar(solicitud)

        self.viaje = self.viajes.crear(
            solicitud=solicitud, pasajero=pasajero, conductor=conductor,
            tarifa_final=10,
        )
        self.viaje.estado = EstadoViaje.FINALIZADO
        self.viajes.guardar(self.viaje)

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

    def test_puntuacion_cero_es_rechazada(self):
        """En SQLite el CHECK solo exigía >= 0, así que un 0 entraba si se
        saltaba la validación de Django. Ahora lo rechaza la entidad."""
        respuesta = self.client.post(
            '/api/calificaciones/',
            {'viaje': str(self.viaje.id), 'puntuacion': 0, 'comentario': ''},
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
