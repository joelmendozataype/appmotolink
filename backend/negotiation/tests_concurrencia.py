from core.testing import FirestoreTestCase
from users.domain.entities import RolUsuario


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
        # Tres sesiones distintas: el pasajero y los dos conductores que
        # compiten por su solicitud.
        self.client = self.cliente_de(self.pasajero)
        self.client_a = self.cliente_de(self.conductor_a.usuario)
        self.client_b = self.cliente_de(self.conductor_b.usuario)

    def test_dos_conductores_responden_y_solo_uno_es_seleccionable(self):
        """Ambos conductores pueden responder a la misma solicitud abierta
        (ambos compiten); el pasajero solo puede seleccionar una vez."""
        respuesta_a = self.client_a.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {}, format='json',
        )
        self.assertEqual(respuesta_a.status_code, 201)

        respuesta_b = self.client_b.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/contraofertar/',
            {'tarifa': 8}, format='json',
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
        oferta = self.client_a.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {}, format='json',
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
        respuesta = self.client_a.post(
            '/api/solicitudes-viaje/00000000-0000-0000-0000-000000000000/aceptar/',
            {}, format='json',
        )
        self.assertEqual(respuesta.status_code, 404)

    def test_mototaxista_sin_perfil_de_vehiculo_devuelve_404(self):
        """El conductor ya no llega en el cuerpo, sale de la sesión. Queda
        el caso de un usuario con rol mototaxista al que le falta el
        perfil de vehículo."""
        sin_perfil = self.crear_usuario(
            nombre='Sin Perfil', correo='sin.perfil@motolink.com',
            rol=RolUsuario.MOTOTAXISTA,
        )
        respuesta = self.cliente_de(sin_perfil).post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {}, format='json',
        )
        self.assertEqual(respuesta.status_code, 404)
