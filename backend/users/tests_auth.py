from django.test import TestCase
from rest_framework.test import APIClient

from users.infrastructure.models import RolUsuario, Usuario


class SesionAuthTests(TestCase):
    """Cubre la persistencia de sesión tras el login: /me, logout, y que
    las acciones protegidas exijan sesión activa (no JWT, autenticación
    propia por cookie de sesión Django, ver core.authentication)."""

    def setUp(self):
        self.client = APIClient()
        self.usuario = Usuario.objects.create(
            nombre='Ana Torres', correo='ana.auth@motolink.com',
            rol=RolUsuario.PASAJERO,
        )
        self.usuario.set_password('clave123')
        self.usuario.save()

    def _login(self):
        return self.client.post(
            '/api/usuarios/login/',
            {'correo': 'ana.auth@motolink.com', 'contrasena': 'clave123'},
            format='json',
        )

    def test_me_requiere_sesion_activa(self):
        respuesta = self.client.get('/api/usuarios/me/')
        # DRF responde 403 (no 401) porque SesionUsuarioAuthentication no
        # define authenticate_header; es el comportamiento estándar, no
        # un caso de WWW-Authenticate.
        self.assertEqual(respuesta.status_code, 403)

    def test_me_devuelve_el_usuario_tras_login(self):
        self._login()
        respuesta = self.client.get('/api/usuarios/me/')
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data['correo'], 'ana.auth@motolink.com')

    def test_logout_termina_la_sesion(self):
        self._login()
        respuesta = self.client.post('/api/usuarios/logout/')
        self.assertEqual(respuesta.status_code, 204)

        # Sin sesión, /me vuelve a exigir autenticación.
        respuesta = self.client.get('/api/usuarios/me/')
        # DRF responde 403 (no 401) porque SesionUsuarioAuthentication no
        # define authenticate_header; es el comportamiento estándar, no
        # un caso de WWW-Authenticate.
        self.assertEqual(respuesta.status_code, 403)

    def test_usuario_inactivo_no_puede_autenticarse_via_me(self):
        self._login()
        self.usuario.is_active = False
        self.usuario.save()

        respuesta = self.client.get('/api/usuarios/me/')
        # DRF responde 403 (no 401) porque SesionUsuarioAuthentication no
        # define authenticate_header; es el comportamiento estándar, no
        # un caso de WWW-Authenticate.
        self.assertEqual(respuesta.status_code, 403)
