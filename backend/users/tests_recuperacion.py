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

    # --- no filtrar quién tiene cuenta ----------------------------------

    def test_un_correo_inexistente_responde_igual(self):
        """Si la respuesta cambiara, cualquiera podría averiguar quién
        tiene cuenta probando direcciones."""
        conocido = self._pedir()
        cache.clear()
        desconocido = self._pedir('nadie@motolink.com')

        self.assertEqual(conocido.status_code, desconocido.status_code)
        self.assertEqual(conocido.data['detail'], desconocido.data['detail'])
        # Pero solo se envía correo al que existe.
        self.assertEqual(len(mail.outbox), 1)

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
