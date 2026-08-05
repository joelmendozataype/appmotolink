from rest_framework.test import APIClient

from core.testing import FirestoreTestCase


class ConcurrenciaNegociacionTests(FirestoreTestCase):
    """Casos donde dos conductores compiten por la misma solicitud, y
    entradas inválidas/inexistentes que deben fallar de forma controlada
    en vez de romper el servidor.

    Sobre Firestore las garantías vienen de dos primitivas en vez de una
    transacción SQL: el id determinista de la oferta (una por conductor y
    solicitud) y el cambio de estado condicional al cerrar la solicitud.
    """

    def setUp(self):
        super().setUp()
        self.client = APIClient()
        self.pasajero = self.crear_usuario(
            nombre='Pasajero Test', correo='pasajero.conc@motolink.com',
        )
        self.solicitud = self.crear_solicitud(pasajero=self.pasajero, tarifa=10)

        self.conductor_a = self.crear_mototaxista(
            nombre='Conductor A', correo='conductor.a@motolink.com',
            licencia='LIC-A', placa='AAA-001',
        )
        self.conductor_b = self.crear_mototaxista(
            nombre='Conductor B', correo='conductor.b@motolink.com',
            licencia='LIC-B', placa='BBB-002', marca='Yamaha', modelo='Crypton',
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

    def test_seleccionar_la_misma_oferta_dos_veces_devuelve_409(self):
        """Doble tap del pasajero: la segunda selección no debe crear un
        segundo viaje para la misma solicitud."""
        oferta = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {'conductor_id': str(self.conductor_a.usuario_id)}, format='json',
        ).data

        primera = self.client.post(f"/api/ofertas/{oferta['id']}/seleccionar/")
        self.assertEqual(primera.status_code, 201)

        segunda = self.client.post(f"/api/ofertas/{oferta['id']}/seleccionar/")
        self.assertEqual(segunda.status_code, 409)

        viajes = self.viajes.listar_por_usuario(self.pasajero.id)
        self.assertEqual(len(viajes), 1)

    def test_seleccionar_oferta_inexistente_devuelve_404_no_500(self):
        """Bug real encontrado por esta prueba: seleccionar un id de
        oferta que no existe lanzaba un 500 sin manejar. Corregido para
        devolver 404 controlado — ver negotiation/presentation/views.py."""
        respuesta = self.client.post(
            '/api/ofertas/00000000-0000-0000-0000-000000000000/seleccionar/',
        )
        self.assertEqual(respuesta.status_code, 404)
        self.assertIn('detail', respuesta.data)

    def test_aceptar_con_solicitud_inexistente_devuelve_404_no_500(self):
        respuesta = self.client.post(
            '/api/solicitudes-viaje/00000000-0000-0000-0000-000000000000/aceptar/',
            {'conductor_id': str(self.conductor_a.usuario_id)}, format='json',
        )
        self.assertEqual(respuesta.status_code, 404)

    def test_aceptar_con_conductor_inexistente_devuelve_404(self):
        respuesta = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {'conductor_id': '00000000-0000-0000-0000-000000000000'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 404)
