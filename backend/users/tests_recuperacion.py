"""Recuperación de contraseña.

El código llega por correo, así que los tests leen el buzón que Django
usa en pruebas (`django.core.mail.outbox`) en vez de enviar nada real.
"""
from datetime import timedelta

from django.core import mail
from django.core.cache import cache
from django.test import override_settings
from rest_framework.test import APIClient

from core.testing import FirestoreTestCase
from users.infrastructure.recuperacion_repository import RecuperacionRepository


@override_settings(EMAIL_BACKEND='django.core.mail.backends.locmem.EmailBackend')
class RecuperacionTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        cache.clear()
        mail.outbox.clear()
        self.client = APIClient()
        self.usuario = self.crear_usuario(
            nombre='Ana Torres', correo='ana.rec@motolink.com',
            contrasena='ClaveVieja2026',
        )
        self.repo = RecuperacionRepository()

    def _pedir(self, correo='ana.rec@motolink.com'):
        return self.client.post(
            '/api/usuarios/recuperar/', {'correo': correo}, format='json',
        )

    def _codigo_del_correo(self):
        """Extrae los 6 dígitos del mensaje enviado."""
        import re

        return re.search(r'\b(\d{6})\b', mail.outbox[-1].body).group(1)

    def _restablecer(self, codigo, contrasena='ClaveNueva2026',
                     correo='ana.rec@motolink.com'):
        return self.client.post(
            '/api/usuarios/restablecer/',
            {'correo': correo, 'codigo': codigo, 'contrasena': contrasena},
            format='json',
        )

    # --- camino feliz ---------------------------------------------------

    def test_el_codigo_llega_por_correo(self):
        self.assertEqual(self._pedir().status_code, 200)
        self.assertEqual(len(mail.outbox), 1)
        self.assertIn('ana.rec@motolink.com', mail.outbox[0].to)
        self.assertRegex(mail.outbox[0].body, r'\b\d{6}\b')

    def test_con_el_codigo_se_cambia_la_contrasena(self):
        self._pedir()
        respuesta = self._restablecer(self._codigo_del_correo())
        self.assertEqual(respuesta.status_code, 200)

        # La nueva sirve y la vieja ya no.
        self.assertEqual(
            self.client.post(
                '/api/usuarios/login/',
                {'correo': 'ana.rec@motolink.com',
                 'contrasena': 'ClaveNueva2026'},
                format='json',
            ).status_code,
            200,
        )
        self.assertEqual(
            APIClient().post(
                '/api/usuarios/login/',
                {'correo': 'ana.rec@motolink.com',
                 'contrasena': 'ClaveVieja2026'},
                format='json',
            ).status_code,
            401,
        )

    # --- solo los correos registrados ------------------------------------
    #
    # Esta sección sustituyó a la anterior, que exigía la respuesta
    # contraria: que un correo desconocido respondiera igual que uno
    # registrado, para no revelar quién tiene cuenta. Se cambió a
    # petición expresa, porque el usuario que se equivocaba al escribir su
    # correo se quedaba esperando un mensaje que nunca llegaba. La
    # contrapartida —se puede averiguar qué direcciones existen— quedó
    # asumida y se frena con el límite por origen de /existe/.

    def test_un_correo_sin_cuenta_es_rechazado(self):
        respuesta = self._pedir('nadie@motolink.com')

        self.assertEqual(respuesta.status_code, 404)
        self.assertEqual(respuesta.data['detail'], 'Ese correo no está registrado.')
        # Y desde luego no se manda nada.
        self.assertEqual(len(mail.outbox), 0)

    def test_una_cuenta_desactivada_tampoco_recupera(self):
        """Dar de baja a alguien no puede dejarle una puerta abierta."""
        self.usuario.is_active = False
        self.usuarios.guardar(self.usuario)

        self.assertEqual(self._pedir().status_code, 404)
        self.assertEqual(len(mail.outbox), 0)

    def test_existe_responde_si_el_correo_tiene_cuenta(self):
        registrado = self.client.get(
            '/api/usuarios/existe/', {'correo': 'ana.rec@motolink.com'},
        )
        desconocido = self.client.get(
            '/api/usuarios/existe/', {'correo': 'nadie@motolink.com'},
        )

        self.assertEqual(registrado.status_code, 200)
        self.assertTrue(registrado.data['registrado'])
        self.assertFalse(desconocido.data['registrado'])

    def test_existe_no_necesita_sesion(self):
        """Se consulta desde la pantalla de recuperación, sin haber
        entrado: si exigiera sesión no serviría para nada."""
        respuesta = self.client.get(
            '/api/usuarios/existe/', {'correo': 'ana.rec@motolink.com'},
        )
        self.assertEqual(respuesta.status_code, 200)

    def test_existe_rechaza_lo_que_no_es_un_correo(self):
        respuesta = self.client.get('/api/usuarios/existe/', {'correo': '12332werrd'})
        self.assertEqual(respuesta.status_code, 400)

    # --- seguridad del código -------------------------------------------

    def test_el_codigo_no_se_guarda_en_claro(self):
        self._pedir()
        codigo = self._codigo_del_correo()
        guardado = self.store.get('recuperaciones', 'ana.rec@motolink.com')
        self.assertNotIn(codigo, str(guardado))

    def test_un_codigo_equivocado_no_sirve(self):
        self._pedir()
        self.assertEqual(self._restablecer('000000').status_code, 400)

    def test_el_codigo_es_de_un_solo_uso(self):
        self._pedir()
        codigo = self._codigo_del_correo()
        self.assertEqual(self._restablecer(codigo).status_code, 200)
        self.assertEqual(
            self._restablecer(codigo, 'OtraClave2026').status_code, 400,
        )

    def test_un_codigo_caducado_no_sirve(self):
        self._pedir()
        codigo_guardado = self.repo.buscar('ana.rec@motolink.com')
        codigo_guardado.expira_en -= timedelta(minutes=30)
        self.repo.guardar('ana.rec@motolink.com', codigo_guardado)

        self.assertEqual(
            self._restablecer(self._codigo_del_correo()).status_code, 400,
        )

    def test_tras_varios_fallos_el_codigo_se_bloquea(self):
        """Seis dígitos son adivinables si se permiten intentos ilimitados."""
        self._pedir()
        codigo = self._codigo_del_correo()
        for _ in range(5):
            self._restablecer('999999')

        # Aun con el código correcto, ya no se acepta.
        self.assertEqual(self._restablecer(codigo).status_code, 400)

    def test_pedir_uno_nuevo_invalida_el_anterior(self):
        self._pedir()
        primero = self._codigo_del_correo()
        self._pedir()

        self.assertEqual(self._restablecer(primero).status_code, 400)
        self.assertEqual(
            self._restablecer(self._codigo_del_correo()).status_code, 200,
        )

    def test_la_contrasena_nueva_se_valida(self):
        self._pedir()
        respuesta = self._restablecer(self._codigo_del_correo(), '123')
        self.assertEqual(respuesta.status_code, 400)

    def test_se_limita_cuantos_codigos_se_piden(self):
        """Sin límite, esta ruta serviría para llenarle el buzón a alguien."""
        codigos = [self._pedir().status_code for _ in range(5)]
        self.assertIn(429, codigos)
