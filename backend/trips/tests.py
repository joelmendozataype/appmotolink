from django.test import TestCase
from rest_framework.test import APIClient

from trips.infrastructure.models import SolicitudViaje, Viaje
from users.infrastructure.models import Mototaxista, RolUsuario, Usuario


class HistorialTests(TestCase):
    """El historial debe incluir los viajes del usuario tanto si participó
    como pasajero como si participó como conductor (bug real encontrado y
    corregido: el filtro original solo consideraba al pasajero)."""

    def setUp(self):
        self.client = APIClient()
        self.pasajero = Usuario.objects.create(
            nombre='Pasajero Test', correo='pasajero.hist@motolink.com',
            rol=RolUsuario.PASAJERO,
        )
        usuario_conductor = Usuario.objects.create(
            nombre='Conductor Test', correo='conductor.hist@motolink.com',
            rol=RolUsuario.MOTOTAXISTA,
        )
        self.conductor = Mototaxista.objects.create(
            usuario=usuario_conductor, licencia='LIC-H', placa='HIS-001',
            marca_vehiculo='Honda', modelo_vehiculo='Wave',
        )
        solicitud = SolicitudViaje.objects.create(
            pasajero=self.pasajero, origen='A', destino='B',
            tarifa_propuesta=10.0, estado='aceptada',
        )
        self.viaje = Viaje.objects.create(
            solicitud=solicitud, pasajero=self.pasajero, conductor=self.conductor,
            tarifa_final=10.0, estado='finalizado',
        )

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
        solicitud_activa = SolicitudViaje.objects.create(
            pasajero=self.pasajero, origen='C', destino='D',
            tarifa_propuesta=8.0, estado='aceptada',
        )
        Viaje.objects.create(
            solicitud=solicitud_activa, pasajero=self.pasajero,
            conductor=self.conductor, tarifa_final=8.0, estado='asignado',
        )

        respuesta = self.client.get(
            f'/api/viajes/activo/?usuarioId={self.conductor.usuario_id}',
        )
        self.assertEqual(respuesta.status_code, 200)

        respuesta = self.client.get(
            f'/api/viajes/activo/?usuarioId={self.pasajero.id}',
        )
        self.assertEqual(respuesta.status_code, 200)
