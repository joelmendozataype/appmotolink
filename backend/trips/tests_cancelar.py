"""Cancelación de solicitudes y viajes.

Los estados 'cancelada' y 'cancelado' existían en el código desde el
principio pero no los usaba nadie: un pasajero que se arrepentía no tenía
forma de echarse atrás.
"""
from core.testing import FirestoreTestCase
from trips.domain.entities import EstadoSolicitud, EstadoViaje


class CancelarSolicitudTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Ana', correo='ana.canc@motolink.com',
        )
        self.otro = self.crear_usuario(
            nombre='Beto', correo='beto.canc@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Carlos', correo='carlos.canc@motolink.com',
            licencia='LIC-C', placa='CAN-001',
        )
        self.client = self.cliente_de(self.pasajero)
        self.solicitud = self.crear_solicitud(pasajero=self.pasajero)

    def test_el_pasajero_cancela_su_solicitud_pendiente(self):
        respuesta = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/',
        )
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data['estado'], EstadoSolicitud.CANCELADA)
        self.assertEqual(
            self.solicitudes.obtener_por_id(self.solicitud.id).estado,
            EstadoSolicitud.CANCELADA,
        )

    def test_cancelar_no_borra_la_solicitud(self):
        """A diferencia de destroy: el conductor que ya ofertó debe poder
        ver qué pasó, y la solicitud sigue contando en el historial."""
        self.client.post(f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/')
        self.assertIsNotNone(self.solicitudes.obtener_por_id(self.solicitud.id))

    def test_una_solicitud_cancelada_sale_de_las_disponibles(self):
        disponibles = [s.id for s in self.solicitudes.listar_disponibles()]
        self.assertIn(self.solicitud.id, disponibles)

        self.client.post(f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/')

        disponibles = [s.id for s in self.solicitudes.listar_disponibles()]
        self.assertNotIn(self.solicitud.id, disponibles)

    def test_nadie_mas_puede_cancelar_una_solicitud_ajena(self):
        respuesta = self.cliente_de(self.otro).post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/',
        )
        self.assertEqual(respuesta.status_code, 403)
        self.assertEqual(
            self.solicitudes.obtener_por_id(self.solicitud.id).estado,
            EstadoSolicitud.PENDIENTE,
        )

    def test_no_se_cancela_dos_veces(self):
        primera = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/',
        )
        self.assertEqual(primera.status_code, 200)

        segunda = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/',
        )
        self.assertEqual(segunda.status_code, 409)

    def test_no_se_cancela_una_solicitud_ya_aceptada(self):
        """Con un viaje asignado, lo que se cancela es el viaje."""
        oferta = self.cliente_de(self.conductor.usuario).post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {}, format='json',
        ).data
        self.client.post(f"/api/ofertas/{oferta['id']}/seleccionar/")

        respuesta = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/',
        )
        self.assertEqual(respuesta.status_code, 409)

    def test_se_puede_cancelar_estando_en_negociacion(self):
        self.cliente_de(self.conductor.usuario).post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/aceptar/',
            {}, format='json',
        )
        self.assertEqual(
            self.solicitudes.obtener_por_id(self.solicitud.id).estado,
            EstadoSolicitud.EN_NEGOCIACION,
        )

        respuesta = self.client.post(
            f'/api/solicitudes-viaje/{self.solicitud.id}/cancelar/',
        )
        self.assertEqual(respuesta.status_code, 200)


class CancelarViajeTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Ana', correo='ana.cv@motolink.com',
        )
        self.intruso = self.crear_usuario(
            nombre='Intruso', correo='intruso.cv@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Carlos', correo='carlos.cv@motolink.com',
            licencia='LIC-V', placa='CAN-002',
        )
        self.client = self.cliente_de(self.pasajero)
        self.client_conductor = self.cliente_de(self.conductor.usuario)

        solicitud = self.crear_solicitud(pasajero=self.pasajero)
        solicitud.estado = EstadoSolicitud.ACEPTADA
        self.solicitudes.guardar(solicitud)
        self.viaje = self.viajes.crear(
            solicitud=solicitud, pasajero=self.pasajero,
            conductor=self.conductor, tarifa_final=10,
        )

    def test_el_pasajero_cancela_el_viaje(self):
        respuesta = self.client.post(f'/api/viajes/{self.viaje.id}/cancelar/')
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data['estado'], EstadoViaje.CANCELADO)

    def test_el_conductor_tambien_puede_cancelar(self):
        respuesta = self.client_conductor.post(
            f'/api/viajes/{self.viaje.id}/cancelar/',
        )
        self.assertEqual(respuesta.status_code, 200)

    def test_un_extrano_no_puede_cancelar(self):
        respuesta = self.cliente_de(self.intruso).post(
            f'/api/viajes/{self.viaje.id}/cancelar/',
        )
        self.assertEqual(respuesta.status_code, 403)
        self.assertEqual(
            self.viajes.obtener_por_id(self.viaje.id).estado,
            EstadoViaje.ASIGNADO,
        )

    def test_cancelar_sella_la_fecha_de_cierre(self):
        respuesta = self.client.post(f'/api/viajes/{self.viaje.id}/cancelar/')
        self.assertIsNotNone(respuesta.data['finalizado_en'])

    def test_un_viaje_cancelado_ya_no_es_el_activo(self):
        self.client.post(f'/api/viajes/{self.viaje.id}/cancelar/')
        self.assertEqual(self.client.get('/api/viajes/activo/').status_code, 404)

    def test_no_se_puede_cancelar_un_viaje_ya_finalizado(self):
        self.client.put(f'/api/viajes/{self.viaje.id}/finalizar/')
        respuesta = self.client.post(f'/api/viajes/{self.viaje.id}/cancelar/')
        self.assertEqual(respuesta.status_code, 409)

    def test_no_se_puede_finalizar_un_viaje_ya_cancelado(self):
        self.client.post(f'/api/viajes/{self.viaje.id}/cancelar/')
        respuesta = self.client.put(f'/api/viajes/{self.viaje.id}/finalizar/')
        self.assertEqual(respuesta.status_code, 409)

    def test_las_dos_partes_a_la_vez_no_cierran_dos_veces(self):
        """El pasajero finaliza y el conductor cancela casi a la vez: solo
        uno de los dos debe aplicarse."""
        primera = self.client.put(f'/api/viajes/{self.viaje.id}/finalizar/')
        segunda = self.client_conductor.post(
            f'/api/viajes/{self.viaje.id}/cancelar/',
        )
        self.assertEqual(primera.status_code, 200)
        self.assertEqual(segunda.status_code, 409)
        self.assertEqual(
            self.viajes.obtener_por_id(self.viaje.id).estado,
            EstadoViaje.FINALIZADO,
        )
