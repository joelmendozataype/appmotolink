"""El listado que ve el mototaxista.

Todas las solicitudes se le mostraban iguales, aunque ya hubiera
respondido a algunas. Pulsaba "Ofertar" y recibía un 409 "Ya respondiste
a esta solicitud" sin haber tenido forma de saberlo antes.
"""
from core.testing import FirestoreTestCase
from trips.domain.entities import EstadoSolicitud


class ListadoConductorTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Ana', correo='ana.list@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Carlos', correo='carlos.list@motolink.com',
            licencia='LIC-L', placa='LST-001',
        )
        self.otro = self.crear_mototaxista(
            nombre='Dario', correo='dario.list@motolink.com',
            licencia='LIC-L2', placa='LST-002',
        )
        self.client = self.cliente_de(self.conductor.usuario)

    def _listar(self, cliente=None):
        return (cliente or self.client).get('/api/solicitudes-viaje/').data

    def test_la_solicitud_trae_su_fecha_de_creacion(self):
        """Sin fecha no hay forma de saber si es de hace un minuto o de
        hace tres días."""
        self.crear_solicitud(pasajero=self.pasajero)
        datos = self._listar()
        self.assertIsNotNone(datos[0]['creado_en'])

    def test_marca_las_que_el_conductor_ya_respondio(self):
        respondida = self.crear_solicitud(pasajero=self.pasajero, origen='A')
        libre = self.crear_solicitud(pasajero=self.pasajero, origen='B')

        self.client.post(
            f'/api/solicitudes-viaje/{respondida.id}/aceptar/', {}, format='json',
        )

        por_id = {s['id']: s for s in self._listar()}
        self.assertTrue(por_id[respondida.id]['ya_respondida'])
        self.assertFalse(por_id[libre.id]['ya_respondida'])

    def test_la_marca_es_de_cada_conductor(self):
        """Que uno haya respondido no debe bloquear a los demás: compiten
        por la misma solicitud."""
        solicitud = self.crear_solicitud(pasajero=self.pasajero)
        self.client.post(
            f'/api/solicitudes-viaje/{solicitud.id}/aceptar/', {}, format='json',
        )

        para_el_otro = self._listar(self.cliente_de(self.otro.usuario))
        self.assertFalse(para_el_otro[0]['ya_respondida'])

    def test_para_el_pasajero_la_marca_no_aplica(self):
        """Un pasajero no oferta, así que el dato no tiene sentido y se
        devuelve nulo en vez de un false engañoso."""
        self.crear_solicitud(pasajero=self.pasajero)
        datos = self._listar(self.cliente_de(self.pasajero))
        self.assertIsNone(datos[0]['ya_respondida'])

    def test_el_estado_viaja_en_el_listado(self):
        """La app pinta el botón según el estado, así que tiene que llegar."""
        solicitud = self.crear_solicitud(pasajero=self.pasajero)
        self.assertEqual(self._listar()[0]['estado'], EstadoSolicitud.PENDIENTE)

        self.client.post(
            f'/api/solicitudes-viaje/{solicitud.id}/aceptar/', {}, format='json',
        )
        self.assertEqual(
            self._listar()[0]['estado'], EstadoSolicitud.EN_NEGOCIACION,
        )
