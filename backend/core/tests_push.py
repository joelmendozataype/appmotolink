"""Notificaciones push.

Socket.IO solo llega a quien tiene la app abierta; un mototaxista con el
teléfono en el bolsillo no se entera de una solicitud nueva, que es justo
cuando más falta hace.

Los tests usan PushSilencioso: no sale nada a Firebase, pero se comprueba
a quién se habría avisado y con qué.
"""
from rest_framework.test import APIClient

from core.push.dispositivos import FirestoreDispositivoRepository
from core.push.notificador import NotificadorConPush
from core.push.sender import PushSilencioso
from core.testing import FirestoreTestCase
from users.domain.entities import RolUsuario


class RegistroDispositivoTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        self.usuario = self.crear_usuario(
            nombre='Ana', correo='ana.push@motolink.com',
        )
        self.client = self.cliente_de(self.usuario)
        self.repo = FirestoreDispositivoRepository()

    def test_registrar_asocia_el_token_al_usuario_en_sesion(self):
        respuesta = self.client.post(
            '/api/dispositivos/', {'token': 'tok-123'}, format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        self.assertEqual(self.repo.tokens_de(self.usuario.id), ['tok-123'])

    def test_sin_sesion_no_se_registra_nada(self):
        respuesta = APIClient().post(
            '/api/dispositivos/', {'token': 'tok-anon'}, format='json',
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_registrar_dos_veces_no_duplica(self):
        for _ in range(3):
            self.client.post(
                '/api/dispositivos/', {'token': 'tok-123'}, format='json',
            )
        self.assertEqual(len(self.repo.tokens_de(self.usuario.id)), 1)

    def test_un_telefono_compartido_pasa_al_nuevo_dueno(self):
        """Si otra persona inicia sesión en el mismo aparato, el token debe
        seguirla: si no, recibiría notificaciones ajenas."""
        self.client.post('/api/dispositivos/', {'token': 'tok-compartido'},
                         format='json')
        otro = self.crear_usuario(nombre='Beto', correo='beto.push@motolink.com')
        self.cliente_de(otro).post(
            '/api/dispositivos/', {'token': 'tok-compartido'}, format='json',
        )

        self.assertEqual(self.repo.tokens_de(self.usuario.id), [])
        self.assertEqual(self.repo.tokens_de(otro.id), ['tok-compartido'])

    def test_dar_de_baja_al_cerrar_sesion(self):
        self.client.post('/api/dispositivos/', {'token': 'tok-123'},
                         format='json')
        respuesta = self.client.delete(
            '/api/dispositivos/', {'token': 'tok-123'}, format='json',
        )
        self.assertEqual(respuesta.status_code, 204)
        self.assertEqual(self.repo.tokens_de(self.usuario.id), [])

    def test_un_usuario_puede_tener_varios_dispositivos(self):
        for token in ('tok-telefono', 'tok-tablet'):
            self.client.post('/api/dispositivos/', {'token': token},
                             format='json')
        self.assertEqual(len(self.repo.tokens_de(self.usuario.id)), 2)


class EnvioDePushTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        self.emisor = PushSilencioso()
        self.dispositivos = FirestoreDispositivoRepository()
        self.notificador = NotificadorConPush(
            sender=self.emisor, dispositivos=self.dispositivos,
        )
        self.pasajero = self.crear_usuario(
            nombre='Ana', correo='ana.envio@motolink.com',
        )
        self.conductor = self.crear_mototaxista(
            nombre='Carlos', correo='carlos.envio@motolink.com',
            licencia='LIC-P', placa='PUS-001',
        )

    def test_una_solicitud_nueva_avisa_a_los_mototaxistas(self):
        self.dispositivos.registrar(self.conductor.usuario_id, 'tok-conductor')
        self.dispositivos.registrar(self.pasajero.id, 'tok-pasajero')

        solicitud = self.crear_solicitud(
            pasajero=self.pasajero, origen='Pampas', destino='Acraquia',
            tarifa=9,
        )
        self.notificador.notificar_solicitud_creada(solicitud)

        self.assertEqual(len(self.emisor.enviados), 1)
        aviso = self.emisor.enviados[0]
        # Solo al conductor: al pasajero no le interesa su propia solicitud.
        self.assertEqual(aviso['tokens'], ['tok-conductor'])
        self.assertIn('Pampas', aviso['cuerpo'])
        self.assertIn('Acraquia', aviso['cuerpo'])
        self.assertEqual(aviso['datos']['solicitudId'], solicitud.id)

    def test_sin_dispositivos_registrados_no_se_envia_nada(self):
        solicitud = self.crear_solicitud(pasajero=self.pasajero)
        self.notificador.notificar_solicitud_creada(solicitud)
        self.assertEqual(self.emisor.enviados, [])

    def test_los_tokens_caducados_se_borran(self):
        """Cuando alguien desinstala la app, Firebase rechaza su token. Si
        no se limpia, la lista crece y cada envío desperdicia intentos."""
        class EmisorConTokenMuerto(PushSilencioso):
            def enviar(self, tokens, titulo, cuerpo, datos=None):
                super().enviar(tokens, titulo, cuerpo, datos)
                return ['tok-muerto']

        self.dispositivos.registrar(self.conductor.usuario_id, 'tok-muerto')
        notificador = NotificadorConPush(
            sender=EmisorConTokenMuerto(), dispositivos=self.dispositivos,
        )
        notificador.notificar_solicitud_creada(
            self.crear_solicitud(pasajero=self.pasajero),
        )

        self.assertEqual(self.dispositivos.tokens_de(self.conductor.usuario_id), [])

    def test_el_administrador_no_recibe_avisos_de_solicitudes(self):
        admin = self.crear_usuario(
            nombre='Admin', correo='admin.push@motolink.com',
            rol=RolUsuario.ADMINISTRADOR,
        )
        self.dispositivos.registrar(admin.id, 'tok-admin')
        self.dispositivos.registrar(self.conductor.usuario_id, 'tok-conductor')

        self.notificador.notificar_solicitud_creada(
            self.crear_solicitud(pasajero=self.pasajero),
        )
        self.assertEqual(self.emisor.enviados[0]['tokens'], ['tok-conductor'])
