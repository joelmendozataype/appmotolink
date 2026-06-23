from django.test import TestCase
from rest_framework.test import APIClient

from users.infrastructure.models import Mototaxista, RolUsuario, Usuario


class LoginRegistroTests(TestCase):
    """Cubre el flujo de autenticación real contra el backend: registro,
    login con credenciales correctas/incorrectas y persistencia de sesión."""

    def setUp(self):
        self.client = APIClient()

    def test_registro_pasajero_no_admite_correo_duplicado(self):
        payload = {
            'nombre': 'Ana Torres', 'correo': 'ana@motolink.com',
            'contrasena': 'clave123', 'rol': RolUsuario.PASAJERO,
        }
        primera = self.client.post('/api/usuarios/', payload, format='json')
        self.assertEqual(primera.status_code, 201)

        segunda = self.client.post('/api/usuarios/', payload, format='json')
        self.assertEqual(segunda.status_code, 400)

    def test_login_con_credenciales_correctas(self):
        usuario = Usuario.objects.create(
            nombre='Ana Torres', correo='ana@motolink.com', rol=RolUsuario.PASAJERO,
        )
        usuario.set_password('clave123')
        usuario.save()

        respuesta = self.client.post(
            '/api/usuarios/login/',
            {'correo': 'ana@motolink.com', 'contrasena': 'clave123'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data['correo'], 'ana@motolink.com')
        # La contraseña nunca se devuelve al cliente.
        self.assertNotIn('contrasena', respuesta.data)

    def test_login_con_contrasena_incorrecta_es_rechazado(self):
        usuario = Usuario.objects.create(
            nombre='Ana Torres', correo='ana@motolink.com', rol=RolUsuario.PASAJERO,
        )
        usuario.set_password('clave123')
        usuario.save()

        respuesta = self.client.post(
            '/api/usuarios/login/',
            {'correo': 'ana@motolink.com', 'contrasena': 'incorrecta'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 401)

    def test_listado_de_pasajeros_excluye_otros_roles(self):
        Usuario.objects.create(
            nombre='Pasajero Uno', correo='p1@motolink.com', rol=RolUsuario.PASAJERO,
        )
        usuario_conductor = Usuario.objects.create(
            nombre='Conductor Uno', correo='c1@motolink.com', rol=RolUsuario.MOTOTAXISTA,
        )
        Mototaxista.objects.create(
            usuario=usuario_conductor, licencia='LIC-1', placa='AAA-111',
            marca_vehiculo='Honda', modelo_vehiculo='Wave',
        )

        respuesta = self.client.get('/api/usuarios/pasajeros/')
        self.assertEqual(respuesta.status_code, 200)
        correos = [u['correo'] for u in respuesta.data]
        self.assertIn('p1@motolink.com', correos)
        self.assertNotIn('c1@motolink.com', correos)

    def test_registro_mototaxista_crea_usuario_y_perfil(self):
        payload = {
            'usuario': {
                'nombre': 'Luis Pérez', 'correo': 'luis@motolink.com',
                'contrasena': 'clave123', 'rol': RolUsuario.MOTOTAXISTA,
            },
            'licencia': 'LIC-9', 'placa': 'XYZ-999',
            'marca_vehiculo': 'Yamaha', 'modelo_vehiculo': 'Crypton',
        }
        respuesta = self.client.post('/api/mototaxistas/', payload, format='json')
        self.assertEqual(respuesta.status_code, 201)
        self.assertTrue(
            Usuario.objects.filter(correo='luis@motolink.com').exists(),
        )
        self.assertTrue(
            Mototaxista.objects.filter(placa='XYZ-999').exists(),
        )
