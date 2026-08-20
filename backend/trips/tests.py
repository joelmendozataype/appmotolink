from core.testing import FirestoreTestCase
from trips.domain.entities import EstadoSolicitud, EstadoViaje


class HistorialTests(FirestoreTestCase):
    """El historial debe incluir los viajes del usuario tanto si participó
    como pasajero como si participó como conductor (bug real encontrado y
    corregido: el filtro original solo consideraba al pasajero)."""

    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Pasajero Test', correo='pasajero.hist@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Conductor Test', correo='conductor.hist@motolink.com',
            licencia='LIC-H', placa='HIS-001',
        )
        # El historial y el viaje activo son siempre los del usuario en
        # sesión, así que cada parte consulta con su propio cliente.
        self.client = self.cliente_de(self.pasajero)
        self.conductor_client = self.cliente_de(self.conductor.usuario)

        solicitud = self.crear_solicitud(pasajero=self.pasajero, tarifa=10)
        solicitud.estado = EstadoSolicitud.ACEPTADA
        self.solicitudes.guardar(solicitud)

        self.viaje = self.viajes.crear(
            solicitud=solicitud, pasajero=self.pasajero,
            conductor=self.conductor, tarifa_final=10,
        )
        self.viaje.estado = EstadoViaje.FINALIZADO
        self.viajes.guardar(self.viaje)

    def test_historial_incluye_el_viaje_para_el_pasajero(self):
        respuesta = self.client.get('/api/historial/')
        ids = [v['id'] for v in respuesta.data['viajes']]
        self.assertIn(str(self.viaje.id), ids)

    def test_historial_incluye_el_viaje_para_el_conductor(self):
        respuesta = self.conductor_client.get('/api/historial/')
        ids = [v['id'] for v in respuesta.data['viajes']]
        self.assertIn(str(self.viaje.id), ids)

    def test_viaje_activo_visible_para_ambas_partes(self):
        solicitud_activa = self.crear_solicitud(
            pasajero=self.pasajero, origen='C', destino='D', tarifa=8,
        )
        solicitud_activa.estado = EstadoSolicitud.ACEPTADA
        self.solicitudes.guardar(solicitud_activa)
        self.viajes.crear(
            solicitud=solicitud_activa, pasajero=self.pasajero,
            conductor=self.conductor, tarifa_final=8,
        )

        respuesta = self.conductor_client.get('/api/viajes/activo/')
        self.assertEqual(respuesta.status_code, 200)

        respuesta = self.client.get('/api/viajes/activo/')
        self.assertEqual(respuesta.status_code, 200)

    def test_viaje_activo_sin_viajes_devuelve_404(self):
        solo = self.crear_usuario(
            nombre='Sin Viajes', correo='sin.viajes@motolink.com',
        )
        respuesta = self.cliente_de(solo).get('/api/viajes/activo/')
        self.assertEqual(respuesta.status_code, 404)


class LugarValidoTests(FirestoreTestCase):
    """Origen y destino deben nombrar un sitio.

    Nace de una prueba real: el formulario aceptaba «.,mnhfg_#» y
    «SX:::S:», que llegaban a la lista del mototaxista sin decirle a dónde
    tenía que ir.
    """

    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Ana Torres', correo='ana.lugar@motolink.com',
        )
        self.client = self.cliente_de(self.pasajero)

    def _crear(self, origen='Ahuaycha', destino='Plaza de Pampas'):
        return self.client.post(
            '/api/solicitudes-viaje/',
            {'origen': origen, 'destino': destino, 'tarifa_propuesta': 5},
            format='json',
        )

    def test_acepta_sitios_reales(self):
        self.assertEqual(self._crear().status_code, 201)
        self.assertEqual(self._crear(origen='Jr. Grau 123').status_code, 201)

    def test_acepta_las_coordenadas_del_gps(self):
        """Es lo que rellena el botón de ubicación de la app."""
        self.assertEqual(self._crear(origen='-12.39031, -74.85911').status_code, 201)

    def test_rechaza_lo_tecleado_al_azar(self):
        self.assertEqual(self._crear(origen='.,mnhfg_#').status_code, 400)
        self.assertEqual(self._crear(destino='SX:::S:').status_code, 400)

    def test_rechaza_vacio(self):
        self.assertEqual(self._crear(origen='   ').status_code, 400)

    def test_rechaza_lo_que_no_nombra_un_sitio(self):
        self.assertEqual(self._crear(destino='123456').status_code, 400)

    def test_se_guarda_recortado(self):
        self.assertEqual(self._crear(origen='  Ahuaycha  ').status_code, 201)
        origenes = [s.origen for s in self.solicitudes.listar()]
        self.assertIn('Ahuaycha', origenes)


class TarifaValidaTests(FirestoreTestCase):
    """La tarifa admite enteros y decimales desde S/ 1, nada más."""

    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Ana Torres', correo='ana.tarifa@motolink.com',
        )
        self.client = self.cliente_de(self.pasajero)

    def _crear(self, tarifa):
        return self.client.post(
            '/api/solicitudes-viaje/',
            {'origen': 'Ahuaycha', 'destino': 'Pampas',
             'tarifa_propuesta': tarifa},
            format='json',
        )

    def test_acepta_enteros_y_decimales(self):
        self.assertEqual(self._crear(5).status_code, 201)
        self.assertEqual(self._crear('12.50').status_code, 201)

    def test_acepta_el_minimo(self):
        self.assertEqual(self._crear(1).status_code, 201)

    def test_rechaza_el_cero(self):
        """Un viaje gratis no es una tarifa, y la solicitud llegaba igual
        a todos los mototaxistas."""
        respuesta = self._crear(0)
        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('mínima', str(respuesta.data['tarifa_propuesta']))

    def test_rechaza_por_debajo_del_minimo(self):
        self.assertEqual(self._crear('0.99').status_code, 400)

    def test_rechaza_negativos(self):
        respuesta = self._crear(-5)
        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('mínima', str(respuesta.data['tarifa_propuesta']))

    def test_rechaza_texto(self):
        self.assertEqual(self._crear('cinco soles').status_code, 400)

    def test_rechaza_mas_de_dos_decimales(self):
        self.assertEqual(self._crear('5.999').status_code, 400)

    def test_la_contraoferta_tambien_se_valida(self):
        """Esa ruta no pasa por ningún serializer: la tarifa llegaba del
        cuerpo de la petición sin comprobar nada."""
        solicitud = self.crear_solicitud(pasajero=self.pasajero, tarifa=5)
        conductor = self.crear_mototaxista(
            nombre='Luis Pérez', correo='luis.tarifa@motolink.com',
            licencia='LIC-T', placa='TAR-001',
        )
        respuesta = self.cliente_de(conductor.usuario).post(
            f'/api/solicitudes-viaje/{solicitud.id}/contraofertar/',
            {'tarifa': -20}, format='json',
        )
        self.assertEqual(respuesta.status_code, 400)


class OrdenDeListadosTests(FirestoreTestCase):
    """Lo más nuevo va arriba.

    En la lista del mototaxista una solicitud de hoy aparecía debajo de
    dos del 6 de agosto: Firestore devuelve los documentos sin orden
    garantizado y nadie los ordenaba.
    """

    def setUp(self):
        super().setUp()
        self.pasajero = self.crear_usuario(
            nombre='Ana Torres', correo='ana.orden@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Luis Pérez', correo='luis.orden@motolink.com',
            licencia='LIC-O', placa='ORD-001',
        )

    def _solicitud(self, origen, momento):
        solicitud = self.crear_solicitud(pasajero=self.pasajero, tarifa=5)
        solicitud.origen = origen
        solicitud.creado_en = momento
        self.solicitudes.guardar(solicitud)
        return solicitud

    def test_las_solicitudes_salen_de_la_mas_nueva_a_la_mas_vieja(self):
        from datetime import datetime, timedelta, timezone

        ahora_mismo = datetime.now(timezone.utc)
        self._solicitud('Vieja', ahora_mismo - timedelta(days=2))
        self._solicitud('Nueva', ahora_mismo)
        self._solicitud('Intermedia', ahora_mismo - timedelta(hours=3))

        respuesta = self.cliente_de(self.conductor.usuario).get(
            '/api/solicitudes-viaje/',
        )
        self.assertEqual(respuesta.status_code, 200)
        origenes = [s['origen'] for s in respuesta.data]
        self.assertEqual(origenes, ['Nueva', 'Intermedia', 'Vieja'])

    def test_las_migradas_sin_fecha_quedan_al_final(self):
        """SQLite no guardaba la fecha: no se sabe cuándo se pidieron, así
        que no pueden competir por el primer puesto."""
        from datetime import datetime, timedelta, timezone

        sin_fecha = self.crear_solicitud(pasajero=self.pasajero, tarifa=5)
        sin_fecha.origen = 'Migrada'
        sin_fecha.creado_en = None
        self.solicitudes.guardar(sin_fecha)
        self._solicitud('Reciente', datetime.now(timezone.utc) - timedelta(days=9))

        respuesta = self.cliente_de(self.conductor.usuario).get(
            '/api/solicitudes-viaje/',
        )
        origenes = [s['origen'] for s in respuesta.data]
        self.assertEqual(origenes[-1], 'Migrada')
