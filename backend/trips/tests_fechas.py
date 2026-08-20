from datetime import timedelta

from core.testing import FirestoreTestCase
from trips.domain.entities import EstadoSolicitud, EstadoViaje


class FechasTests(FirestoreTestCase):
    """Ni SolicitudViaje ni Viaje guardaban cuándo ocurrieron, así que el
    historial no se podía ordenar ni se sabía cuánto duró un viaje."""

    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Ana', correo='ana.fechas@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Carlos', correo='carlos.fechas@motolink.com',
            licencia='LIC-F', placa='FEC-001',
        )
        self.client = self.cliente_de(self.pasajero)

    def _viaje_nuevo(self, origen='A'):
        solicitud = self.crear_solicitud(pasajero=self.pasajero, origen=origen)
        solicitud.estado = EstadoSolicitud.ACEPTADA
        self.solicitudes.guardar(solicitud)
        return self.viajes.crear(
            solicitud=solicitud, pasajero=self.pasajero,
            conductor=self.conductor, tarifa_final=10,
        )

    def test_la_solicitud_se_sella_al_crearse(self):
        respuesta = self.client.post(
            '/api/solicitudes-viaje/',
            {'origen': 'Ahuaycha', 'destino': 'Pampas', 'tarifa_propuesta': 5},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        self.assertIsNotNone(respuesta.data['creado_en'])
        self.assertIsNotNone(
            self.solicitudes.obtener_por_id(respuesta.data['id']).creado_en,
        )

    def test_el_viaje_se_sella_al_asignarse(self):
        viaje = self._viaje_nuevo()
        self.assertIsNotNone(self.viajes.obtener_por_id(viaje.id).creado_en)

    def test_finalizar_sella_la_fecha_de_cierre(self):
        viaje = self._viaje_nuevo()
        self.assertIsNone(viaje.finalizado_en)

        respuesta = self.client.put(f'/api/viajes/{viaje.id}/finalizar/')
        self.assertEqual(respuesta.status_code, 200)
        self.assertIsNotNone(respuesta.data['finalizado_en'])

        guardado = self.viajes.obtener_por_id(viaje.id)
        self.assertEqual(guardado.estado, EstadoViaje.FINALIZADO)
        self.assertIsNotNone(guardado.finalizado_en)

    def test_la_duracion_es_none_mientras_el_viaje_no_termina(self):
        viaje = self._viaje_nuevo()
        self.assertIsNone(viaje.duracion_minutos)

    def test_la_duracion_se_calcula_en_minutos(self):
        viaje = self._viaje_nuevo()
        viaje.finalizado_en = viaje.creado_en + timedelta(minutes=23, seconds=40)
        # 23m40s redondea a 24.
        self.assertEqual(viaje.duracion_minutos, 24)

    def test_los_viajes_migrados_sin_fecha_no_rompen_la_duracion(self):
        """Los datos que vienen de SQLite no tienen fecha: aquella base no
        la guardaba y no hay forma de reconstruirla."""
        viaje = self._viaje_nuevo()
        viaje.creado_en = None
        viaje.finalizado_en = None
        self.assertIsNone(viaje.duracion_minutos)

    def test_el_historial_llega_del_mas_reciente_al_mas_antiguo(self):
        primero = self._viaje_nuevo(origen='Primero')
        segundo = self._viaje_nuevo(origen='Segundo')
        # Se separan explícitamente para que el orden no dependa de que la
        # máquina sea lo bastante lenta entre una creación y la otra.
        primero.creado_en = segundo.creado_en - timedelta(hours=2)
        self.viajes.guardar(primero)

        respuesta = self.client.get('/api/historial/')
        ids = [v['id'] for v in respuesta.data['viajes']]
        self.assertEqual(ids, [segundo.id, primero.id])

    def test_un_viaje_sin_fecha_queda_al_final_del_historial(self):
        con_fecha = self._viaje_nuevo(origen='Con fecha')
        sin_fecha = self._viaje_nuevo(origen='Sin fecha')
        sin_fecha.creado_en = None
        self.viajes.guardar(sin_fecha)

        respuesta = self.client.get('/api/historial/')
        ids = [v['id'] for v in respuesta.data['viajes']]
        self.assertEqual(ids, [con_fecha.id, sin_fecha.id])
