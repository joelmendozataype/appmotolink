from django.test import TestCase
from rest_framework.test import APIClient

from trips.infrastructure.models import SolicitudViaje, Viaje
from users.infrastructure.models import Mototaxista, RolUsuario, Usuario


class FlujoNegociacionTests(TestCase):
    """Cubre el flujo completo de negociación end-to-end vía API REST:
    crear solicitud -> aceptar -> ver ofertas -> seleccionar -> viaje
    asignado -> finalizar -> calificar. Mismo flujo verificado manualmente
    contra el emulador durante el desarrollo."""

    def setUp(self):
        self.client = APIClient()
        self.pasajero = Usuario.objects.create(
            nombre='Pasajero Test', correo='pasajero.test@motolink.com',
            rol=RolUsuario.PASAJERO,
        )
        self.pasajero.set_password('clave123')
        self.pasajero.save()

        usuario_conductor = Usuario.objects.create(
            nombre='Conductor Test', correo='conductor.test@motolink.com',
            rol=RolUsuario.MOTOTAXISTA,
        )
        usuario_conductor.set_password('clave123')
        usuario_conductor.save()
        self.conductor = Mototaxista.objects.create(
            usuario=usuario_conductor, licencia='LIC-TEST', placa='TST-001',
            marca_vehiculo='Honda', modelo_vehiculo='Wave',
        )

    def _crear_solicitud(self, tarifa=10.0):
        respuesta = self.client.post(
            '/api/solicitudes-viaje/',
            {
                'pasajero': str(self.pasajero.id),
                'origen': 'Plaza Pampas',
                'destino': 'Mercado Central',
                'tarifa_propuesta': tarifa,
            },
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        return respuesta.data

    def test_flujo_completo_aceptacion_directa(self):
        solicitud = self._crear_solicitud(tarifa=10.0)
        self.assertEqual(solicitud['estado'], 'pendiente')

        # El conductor acepta la tarifa propuesta tal cual.
        respuesta = self.client.post(
            f"/api/solicitudes-viaje/{solicitud['id']}/aceptar/",
            {'conductor_id': str(self.conductor.usuario_id)},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        oferta = respuesta.data
        self.assertEqual(oferta['tipo'], 'aceptacion')
        self.assertEqual(float(oferta['tarifa']), 10.0)

        # La solicitud pasó a "en negociación" al recibir la primera respuesta.
        solicitud_actualizada = SolicitudViaje.objects.get(id=solicitud['id'])
        self.assertEqual(solicitud_actualizada.estado, 'enNegociacion')

        # El pasajero ve la oferta pendiente.
        respuesta = self.client.get(
            f"/api/solicitudes-viaje/{solicitud['id']}/ofertas/",
        )
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(len(respuesta.data), 1)

        # El pasajero selecciona la oferta: se crea el viaje.
        respuesta = self.client.post(f"/api/ofertas/{oferta['id']}/seleccionar/")
        self.assertEqual(respuesta.status_code, 201)
        viaje = respuesta.data
        self.assertEqual(viaje['estado'], 'asignado')
        self.assertEqual(float(viaje['tarifa_final']), 10.0)

        viaje_db = Viaje.objects.get(id=viaje['id'])
        self.assertEqual(viaje_db.pasajero_id, self.pasajero.id)
        self.assertEqual(viaje_db.conductor_id, self.conductor.usuario_id)

        # Finalizar el viaje.
        respuesta = self.client.put(f"/api/viajes/{viaje['id']}/finalizar/")
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data['estado'], 'finalizado')

        # Calificar el viaje.
        respuesta = self.client.post(
            '/api/calificaciones/',
            {'viaje': viaje['id'], 'puntuacion': 5, 'comentario': 'Excelente'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)

        # El viaje aparece en el historial del pasajero.
        respuesta = self.client.get(
            f"/api/historial/?usuarioId={self.pasajero.id}",
        )
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(len(respuesta.data['viajes']), 1)

    def test_contraoferta_con_tarifa_distinta(self):
        solicitud = self._crear_solicitud(tarifa=10.0)

        respuesta = self.client.post(
            f"/api/solicitudes-viaje/{solicitud['id']}/contraofertar/",
            {'conductor_id': str(self.conductor.usuario_id), 'tarifa': 13.5},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        self.assertEqual(respuesta.data['tipo'], 'contraoferta')
        self.assertEqual(float(respuesta.data['tarifa']), 13.5)

    def test_rechazo_no_es_visible_para_el_pasajero(self):
        solicitud = self._crear_solicitud()

        respuesta = self.client.post(
            f"/api/solicitudes-viaje/{solicitud['id']}/rechazar/",
            {'conductor_id': str(self.conductor.usuario_id)},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)

        # El rechazo no se notifica al pasajero: la lista de ofertas
        # pendientes para esa solicitud sigue vacía.
        respuesta = self.client.get(
            f"/api/solicitudes-viaje/{solicitud['id']}/ofertas/",
        )
        self.assertEqual(respuesta.data, [])

    def test_conductor_no_puede_responder_dos_veces_la_misma_solicitud(self):
        solicitud = self._crear_solicitud()

        primera = self.client.post(
            f"/api/solicitudes-viaje/{solicitud['id']}/aceptar/",
            {'conductor_id': str(self.conductor.usuario_id)},
            format='json',
        )
        self.assertEqual(primera.status_code, 201)

        segunda = self.client.post(
            f"/api/solicitudes-viaje/{solicitud['id']}/contraofertar/",
            {'conductor_id': str(self.conductor.usuario_id), 'tarifa': 5},
            format='json',
        )
        self.assertEqual(segunda.status_code, 409)
        self.assertIn('detail', segunda.data)

    def test_no_se_puede_responder_una_solicitud_ya_aceptada(self):
        solicitud = self._crear_solicitud()
        oferta = self.client.post(
            f"/api/solicitudes-viaje/{solicitud['id']}/aceptar/",
            {'conductor_id': str(self.conductor.usuario_id)},
            format='json',
        ).data
        self.client.post(f"/api/ofertas/{oferta['id']}/seleccionar/")

        # Otro conductor (otro usuario) intenta responder tarde.
        otro_usuario = Usuario.objects.create(
            nombre='Otro Conductor', correo='otro.conductor@motolink.com',
            rol=RolUsuario.MOTOTAXISTA,
        )
        otro_conductor = Mototaxista.objects.create(
            usuario=otro_usuario, licencia='LIC-2', placa='TST-002',
            marca_vehiculo='Yamaha', modelo_vehiculo='Crypton',
        )
        respuesta = self.client.post(
            f"/api/solicitudes-viaje/{solicitud['id']}/aceptar/",
            {'conductor_id': str(otro_conductor.usuario_id)},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 409)
