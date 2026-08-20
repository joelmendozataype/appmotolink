from rest_framework.test import APIClient

from core.testing import FirestoreTestCase
from users.domain.entities import RolUsuario


class LoginRegistroTests(FirestoreTestCase):
    """Cubre el flujo de autenticación real contra el backend: registro,
    login con credenciales correctas/incorrectas y persistencia de sesión."""

    def setUp(self):
        super().setUp()
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
        self.crear_usuario(
            nombre='Ana Torres', correo='ana@motolink.com',
            rol=RolUsuario.PASAJERO, contrasena='clave123',
        )

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
        self.crear_usuario(
            nombre='Ana Torres', correo='ana@motolink.com',
            rol=RolUsuario.PASAJERO, contrasena='clave123',
        )

        respuesta = self.client.post(
            '/api/usuarios/login/',
            {'correo': 'ana@motolink.com', 'contrasena': 'incorrecta'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 401)

    def test_login_es_insensible_a_mayusculas_en_el_correo(self):
        """El índice de correos se normaliza en minúsculas, así que el
        correo se comporta igual que con el UNIQUE de SQLite."""
        self.crear_usuario(
            nombre='Ana Torres', correo='ana@motolink.com',
            rol=RolUsuario.PASAJERO, contrasena='clave123',
        )

        respuesta = self.client.post(
            '/api/usuarios/login/',
            {'correo': 'ANA@Motolink.com', 'contrasena': 'clave123'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 200)

    def test_listado_de_pasajeros_excluye_otros_roles(self):
        self.crear_usuario(nombre='Pasajero Uno', correo='p1@motolink.com')
        self.crear_mototaxista(
            nombre='Conductor Uno', correo='c1@motolink.com',
            licencia='LIC-1', placa='AAA-111',
        )
        # El listado con los correos de todos es dato sensible: solo el
        # administrador, que es quien lo usa desde las pantallas /admin.
        admin = self.crear_usuario(
            nombre='Admin', correo='admin@motolink.com',
            rol=RolUsuario.ADMINISTRADOR,
        )

        respuesta = self.cliente_de(admin).get('/api/usuarios/pasajeros/')
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

        self.assertIsNotNone(self.usuarios.buscar_por_correo('luis@motolink.com'))
        placas = [m.placa for m in self.mototaxistas.listar()]
        self.assertIn('XYZ-999', placas)


class NombreValidoTests(FirestoreTestCase):
    """El nombre solo admite letras y espacios entre palabras.

    La app valida lo mismo, pero esta es la comprobación que cuenta: la
    del cliente se salta llamando a la API directamente.
    """

    def setUp(self):
        super().setUp()
        self.client = APIClient()

    def _registrar(self, nombre, correo='nuevo@motolink.com'):
        return self.client.post(
            '/api/usuarios/',
            {
                'nombre': nombre, 'correo': correo,
                'contrasena': 'ClaveSegura2026', 'rol': RolUsuario.PASAJERO,
            },
            format='json',
        )

    def test_acepta_un_nombre_normal(self):
        self.assertEqual(self._registrar('Joel Mendoza Taype').status_code, 201)

    def test_acepta_tildes_y_enie(self):
        """Rechazarlas dejaría fuera a media provincia."""
        self.assertEqual(self._registrar('José Ñahui Muñoz').status_code, 201)

    def test_rechaza_numeros(self):
        respuesta = self._registrar('Juan123')
        self.assertEqual(respuesta.status_code, 400)
        self.assertIn('números', str(respuesta.data['nombre']))

    def test_rechaza_signos(self):
        self.assertEqual(self._registrar('Juan_Pérez!').status_code, 400)
        self.assertEqual(self._registrar('<script>alert(1)</script>').status_code, 400)

    def test_rechaza_vacio_o_solo_espacios(self):
        self.assertEqual(self._registrar('   ').status_code, 400)

    def test_guarda_el_nombre_sin_espacios_sobrantes(self):
        self.assertEqual(self._registrar('  Ana Torres  ').status_code, 201)
        usuario = self.usuarios.buscar_por_correo('nuevo@motolink.com')
        self.assertEqual(usuario.nombre, 'Ana Torres')

    def test_tambien_se_aplica_al_registro_de_mototaxista(self):
        """Ese serializer anida el de usuario, así que hereda la regla."""
        respuesta = self.client.post(
            '/api/mototaxistas/',
            {
                'usuario': {
                    'nombre': 'Luis 456', 'correo': 'luis.n@motolink.com',
                    'contrasena': 'ClaveSegura2026',
                    'rol': RolUsuario.MOTOTAXISTA,
                },
                'licencia': 'LIC-N', 'placa': 'NUM-001',
                'marca_vehiculo': 'Honda', 'modelo_vehiculo': 'Wave',
            },
            format='json',
        )
        self.assertEqual(respuesta.status_code, 400)


class ValidacionEnLosTresRolesTests(FirestoreTestCase):
    """Las mismas reglas de nombre y correo, entre por donde entre.

    Pasajero y mototaxista se registran por la API; el administrador solo
    por el comando del servidor, que antes no validaba nada.
    """

    def setUp(self):
        super().setUp()
        self.client = APIClient()

    def _registrar(self, rol, nombre, correo):
        return self.client.post(
            '/api/usuarios/',
            {
                'nombre': nombre, 'correo': correo,
                'contrasena': 'ClaveSegura2026', 'rol': rol,
            },
            format='json',
        )

    def test_pasajero_rechaza_nombre_y_correo_invalidos(self):
        self.assertEqual(
            self._registrar(
                RolUsuario.PASAJERO, 'Ana99', 'ana@motolink.com',
            ).status_code,
            400,
        )
        self.assertEqual(
            self._registrar(
                RolUsuario.PASAJERO, 'Ana Torres', '12332werrd',
            ).status_code,
            400,
        )

    def test_mototaxista_rechaza_nombre_y_correo_invalidos(self):
        def alta(nombre, correo):
            return self.client.post(
                '/api/mototaxistas/',
                {
                    'usuario': {
                        'nombre': nombre, 'correo': correo,
                        'contrasena': 'ClaveSegura2026',
                        'rol': RolUsuario.MOTOTAXISTA,
                    },
                    'licencia': 'LIC-V', 'placa': 'VAL-001',
                    'marca_vehiculo': 'Honda', 'modelo_vehiculo': 'Wave',
                },
                format='json',
            )

        self.assertEqual(alta('Luis 99', 'luis@motolink.com').status_code, 400)
        self.assertEqual(alta('Luis Pérez', 'sin-arroba').status_code, 400)

    def test_administrador_rechaza_correo_invalido(self):
        from django.core.management import call_command
        from django.core.management.base import CommandError

        with self.assertRaises(CommandError):
            call_command('crear_administrador', correo='12332werrd')

    def test_administrador_rechaza_nombre_invalido(self):
        from django.core.management import call_command
        from django.core.management.base import CommandError

        with self.assertRaises(CommandError):
            call_command(
                'crear_administrador',
                correo='admin.nuevo@motolink.com', nombre='Admin 123',
            )

    def test_editar_una_cuenta_tambien_valida(self):
        """Da igual el rol: la edición pasa por el mismo serializer."""
        admin = self.crear_usuario(
            nombre='Admin MotoLink', correo='admin.val@motolink.com',
            rol=RolUsuario.ADMINISTRADOR,
        )
        respuesta = self.cliente_de(admin).patch(
            f'/api/usuarios/{admin.id}/', {'nombre': 'Admin 007'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 400)
