"""Pruebas del freno a la fuerza bruta.

Nacen de un fallo real: en producción, doce intentos fallidos seguidos
contra la cuenta de administrador pasaron sin bloqueo, mientras que en
local se cortaban al undécimo. La diferencia estaba en cómo se
identificaba al cliente detrás del proxy.
"""
from django.core.cache import cache
from rest_framework.test import APIClient

from core.testing import FirestoreTestCase
from users.domain.entities import RolUsuario


class LoginThrottleTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        # El contador vive en la caché y es global al proceso: sin esto,
        # un test arrastraría los intentos del anterior.
        cache.clear()
        self.crear_usuario(
            nombre='Victima', correo='victima@motolink.com',
            rol=RolUsuario.PASAJERO, contrasena='MotoLink2026!',
        )

    def _intentar(self, cliente, correo, clave='mala'):
        return cliente.post(
            '/api/usuarios/login/',
            {'correo': correo, 'contrasena': clave}, format='json',
        ).status_code

    def test_se_corta_la_fuerza_bruta_contra_una_cuenta(self):
        cliente = APIClient()
        codigos = [
            self._intentar(cliente, 'victima@motolink.com') for _ in range(13)
        ]
        self.assertIn(429, codigos, 'nunca se aplicó el límite')
        self.assertEqual(codigos[:10], [401] * 10)
        self.assertEqual(codigos[10:], [429] * 3)

    def test_el_limite_sigue_a_la_cuenta_aunque_cambie_el_origen(self):
        """Lo que se protege es la cuenta, no la IP: un atacante rota de
        origen con facilidad, pero no puede cambiar a quién quiere entrar."""
        for _ in range(10):
            self._intentar(APIClient(), 'victima@motolink.com')

        # Cliente nuevo, es decir otro origen desde el punto de vista de
        # la vista: el bloqueo debe seguir aplicándose.
        self.assertEqual(
            self._intentar(APIClient(), 'victima@motolink.com'), 429,
        )

    def test_atacar_una_cuenta_no_bloquea_a_las_demas(self):
        cliente = APIClient()
        for _ in range(11):
            self._intentar(cliente, 'victima@motolink.com')

        self.crear_usuario(
            nombre='Otro', correo='otro@motolink.com',
            contrasena='MotoLink2026!',
        )
        # Otra cuenta, mismo origen: no debe quedar bloqueada por rebote.
        # Solo la protege el límite por origen, más holgado.
        self.assertEqual(
            self._intentar(
                cliente, 'otro@motolink.com', 'MotoLink2026!',
            ),
            200,
        )

    def test_un_login_correcto_no_queda_bloqueado_por_dos_errores(self):
        cliente = APIClient()
        self._intentar(cliente, 'victima@motolink.com')
        self._intentar(cliente, 'victima@motolink.com')

        self.assertEqual(
            self._intentar(cliente, 'victima@motolink.com', 'MotoLink2026!'),
            200,
        )

    def test_sin_correo_no_revienta(self):
        """Sin correo no hay cuenta que proteger; debe responder 400 por
        validación, no romperse al calcular la clave de caché."""
        respuesta = APIClient().post(
            '/api/usuarios/login/', {'contrasena': 'x'}, format='json',
        )
        self.assertEqual(respuesta.status_code, 400)
