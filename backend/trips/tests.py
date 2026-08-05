from rest_framework.test import APIClient

from core.testing import FirestoreTestCase
from trips.domain.entities import EstadoSolicitud, EstadoViaje


class HistorialTests(FirestoreTestCase):
    """El historial debe incluir los viajes del usuario tanto si participó
    como pasajero como si participó como conductor (bug real encontrado y
    corregido: el filtro original solo consideraba al pasajero)."""

    def setUp(self):
        super().setUp()
        self.client = APIClient()
        self.pasajero = self.crear_usuario(
            nombre='Pasajero Test', correo='pasajero.hist@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Conductor Test', correo='conductor.hist@motolink.com',
            licencia='LIC-H', placa='HIS-001',
        )

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
        respuesta = self.client.get(
            f'/api/historial/?usuarioId={self.pasajero.id}',
        )
        ids = [v['id'] for v in respuesta.data['viajes']]
        self.assertIn(str(self.viaje.id), ids)

    def test_historial_incluye_el_viaje_para_el_conductor(self):
        respuesta = self.client.get(
            f'/api/historial/?usuarioId={self.conductor.usuario_id}',
        )
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

        respuesta = self.client.get(
            f'/api/viajes/activo/?usuarioId={self.conductor.usuario_id}',
        )
        self.assertEqual(respuesta.status_code, 200)

        respuesta = self.client.get(
            f'/api/viajes/activo/?usuarioId={self.pasajero.id}',
        )
        self.assertEqual(respuesta.status_code, 200)

    def test_viaje_activo_sin_viajes_devuelve_404(self):
        solo = self.crear_usuario(
            nombre='Sin Viajes', correo='sin.viajes@motolink.com',
        )
        respuesta = self.client.get(f'/api/viajes/activo/?usuarioId={solo.id}')
        self.assertEqual(respuesta.status_code, 404)
