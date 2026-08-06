"""Pruebas de la revisión de seguridad.

Cada test corresponde a un agujero real que existía antes: la API tenía
AllowAny por defecto y el actor de cada operación (pasajero, conductor)
llegaba en el cuerpo de la petición, así que bastaba conocer un id ajeno
para suplantar a cualquiera.

Se verifican dos cosas distintas:

1. Sin sesión no se llega a ningún dato (autenticación).
2. Con sesión, solo se llega a lo propio (autorización).
"""
from rest_framework.test import APIClient

from core.testing import FirestoreTestCase
from trips.domain.entities import EstadoSolicitud, EstadoViaje
from users.domain.entities import RolUsuario


class SinSesionTests(FirestoreTestCase):
    """Antes, todas estas rutas respondían 200 a cualquier desconocido."""

    def setUp(self):
        super().setUp()
        self.anonimo = APIClient()
        self.pasajero = self.crear_usuario(
            nombre='Ana', correo='ana.sec@motolink.com',
        )
        self.solicitud = self.crear_solicitud(pasajero=self.pasajero)

    def test_no_se_pueden_listar_los_usuarios(self):
        """La fuga más grave: devolvía nombre, correo y rol de todos."""
        self.assertEqual(self.anonimo.get('/api/usuarios/').status_code, 403)

    def test_no_se_pueden_listar_las_solicitudes(self):
        self.assertEqual(
            self.anonimo.get('/api/solicitudes-viaje/').status_code, 403,
        )

    def test_no_se_puede_crear_una_solicitud(self):
        respuesta = self.anonimo.post(
            '/api/solicitudes-viaje/',
            {'pasajero': str(self.pasajero.id), 'origen': 'A',
             'destino': 'B', 'tarifa_propuesta': 5},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_no_se_puede_borrar_una_cuenta(self):
        respuesta = self.anonimo.delete(f'/api/usuarios/{self.pasajero.id}/')
        self.assertEqual(respuesta.status_code, 403)
        # La cuenta sigue existiendo.
        self.assertIsNotNone(self.usuarios.buscar_por_correo('ana.sec@motolink.com'))

    def test_la_ruta_de_salud_responde_200_sin_sesion(self):
        """El health check de Render marca el despliegue como fallido si no
        recibe un 2xx. Con /api/solicitudes-viaje/ como ruta de salud, el
        403 de la API tumbaba el despliegue entero: fallo real en el
        primer intento de publicar."""
        respuesta = self.anonimo.get('/api/salud/')
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data['estado'], 'ok')

    def test_la_ruta_de_salud_no_filtra_datos(self):
        """Ser pública no la convierte en una puerta trasera."""
        respuesta = self.anonimo.get('/api/salud/')
        self.assertEqual(set(respuesta.data), {'estado', 'servicio'})

    def test_el_registro_y_el_login_siguen_abiertos(self):
        """Sin estas dos puertas nadie podría llegar a tener sesión."""
        alta = self.anonimo.post(
            '/api/usuarios/',
            {'nombre': 'Nuevo', 'correo': 'nuevo.sec@motolink.com',
             'contrasena': 'MotoLink2026!', 'rol': 'pasajero'},
            format='json',
        )
        self.assertEqual(alta.status_code, 201)

        login = self.anonimo.post(
            '/api/usuarios/login/',
            {'correo': 'nuevo.sec@motolink.com', 'contrasena': 'MotoLink2026!'},
            format='json',
        )
        self.assertEqual(login.status_code, 200)


class SuplantacionTests(FirestoreTestCase):
    """El actor sale de la sesión; el id que venga en el cuerpo se ignora."""

    def setUp(self):
        super().setUp()
        self.ana = self.crear_usuario(nombre='Ana', correo='ana.sup@motolink.com')
        self.beto = self.crear_usuario(nombre='Beto', correo='beto.sup@motolink.com')
        self.conductor = self.crear_mototaxista(
            nombre='Carlos', correo='carlos.sup@motolink.com',
            licencia='LIC-S', placa='SUP-001',
        )
        self.otro_conductor = self.crear_mototaxista(
            nombre='Dario', correo='dario.sup@motolink.com',
            licencia='LIC-S2', placa='SUP-002',
        )
        self.cliente_ana = self.cliente_de(self.ana)
        self.cliente_beto = self.cliente_de(self.beto)
        self.cliente_carlos = self.cliente_de(self.conductor.usuario)

    def test_no_se_puede_crear_una_solicitud_en_nombre_de_otro(self):
        respuesta = self.cliente_ana.post(
            '/api/solicitudes-viaje/',
            # Ana dice ser Beto: el campo se ignora.
            {'pasajero': str(self.beto.id), 'origen': 'A', 'destino': 'B',
             'tarifa_propuesta': 5},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        solicitud = self.solicitudes.obtener_por_id(respuesta.data['id'])
        self.assertEqual(solicitud.pasajero_id, self.ana.id)

    def test_no_se_puede_ofertar_en_nombre_de_otro_conductor(self):
        solicitud = self.crear_solicitud(pasajero=self.ana)
        respuesta = self.cliente_carlos.post(
            f'/api/solicitudes-viaje/{solicitud.id}/aceptar/',
            # Carlos dice ser Dario: también se ignora.
            {'conductor_id': str(self.otro_conductor.usuario_id)},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 201)
        self.assertEqual(respuesta.data['conductor']['placa'], 'SUP-001')

    def test_un_pasajero_no_puede_ofertar(self):
        """Responder solicitudes es cosa de mototaxistas."""
        solicitud = self.crear_solicitud(pasajero=self.ana)
        respuesta = self.cliente_beto.post(
            f'/api/solicitudes-viaje/{solicitud.id}/aceptar/', {}, format='json',
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_un_mototaxista_no_puede_pedir_viajes(self):
        respuesta = self.cliente_carlos.post(
            '/api/solicitudes-viaje/',
            {'origen': 'A', 'destino': 'B', 'tarifa_propuesta': 5},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_no_se_pueden_ver_las_ofertas_de_la_solicitud_ajena(self):
        solicitud = self.crear_solicitud(pasajero=self.ana)
        respuesta = self.cliente_beto.get(
            f'/api/solicitudes-viaje/{solicitud.id}/ofertas/',
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_no_se_puede_seleccionar_conductor_de_una_solicitud_ajena(self):
        solicitud = self.crear_solicitud(pasajero=self.ana)
        oferta = self.cliente_carlos.post(
            f'/api/solicitudes-viaje/{solicitud.id}/aceptar/', {}, format='json',
        ).data
        # Beto intenta cerrar la negociación de Ana.
        respuesta = self.cliente_beto.post(
            f"/api/ofertas/{oferta['id']}/seleccionar/",
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_no_se_puede_cancelar_la_solicitud_ajena(self):
        solicitud = self.crear_solicitud(pasajero=self.ana)
        respuesta = self.cliente_beto.delete(
            f'/api/solicitudes-viaje/{solicitud.id}/',
        )
        self.assertEqual(respuesta.status_code, 403)


class ViajeAjenoTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        self.ana = self.crear_usuario(nombre='Ana', correo='ana.v@motolink.com')
        self.intruso = self.crear_usuario(
            nombre='Intruso', correo='intruso.v@motolink.com',
        )
        conductor = self.crear_mototaxista(
            nombre='Carlos', correo='carlos.v@motolink.com',
            licencia='LIC-V', placa='VIA-001',
        )
        solicitud = self.crear_solicitud(pasajero=self.ana)
        solicitud.estado = EstadoSolicitud.ACEPTADA
        self.solicitudes.guardar(solicitud)
        self.viaje = self.viajes.crear(
            solicitud=solicitud, pasajero=self.ana, conductor=conductor,
            tarifa_final=10,
        )
        self.cliente_ana = self.cliente_de(self.ana)
        self.cliente_intruso = self.cliente_de(self.intruso)

    def test_un_extrano_no_puede_ver_el_viaje(self):
        respuesta = self.cliente_intruso.get(f'/api/viajes/{self.viaje.id}/')
        self.assertEqual(respuesta.status_code, 403)

    def test_un_extrano_no_puede_finalizar_el_viaje(self):
        respuesta = self.cliente_intruso.put(
            f'/api/viajes/{self.viaje.id}/finalizar/',
        )
        self.assertEqual(respuesta.status_code, 403)
        self.assertNotEqual(
            self.viajes.obtener_por_id(self.viaje.id).estado,
            EstadoViaje.FINALIZADO,
        )

    def test_el_historial_ajeno_no_se_puede_consultar(self):
        """El parámetro usuarioId se ignora: antes servía para espiar."""
        respuesta = self.cliente_intruso.get(
            f'/api/historial/?usuarioId={self.ana.id}',
        )
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(respuesta.data['viajes'], [])

    def test_el_viaje_activo_ajeno_no_se_puede_espiar(self):
        respuesta = self.cliente_intruso.get(
            f'/api/viajes/activo/?usuarioId={self.ana.id}',
        )
        self.assertEqual(respuesta.status_code, 404)

    def test_solo_el_pasajero_califica_su_viaje(self):
        self.viaje.estado = EstadoViaje.FINALIZADO
        self.viajes.guardar(self.viaje)
        respuesta = self.cliente_intruso.post(
            '/api/calificaciones/',
            {'viaje': str(self.viaje.id), 'puntuacion': 1, 'comentario': ''},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_no_se_califica_un_viaje_sin_terminar(self):
        respuesta = self.cliente_ana.post(
            '/api/calificaciones/',
            {'viaje': str(self.viaje.id), 'puntuacion': 5, 'comentario': ''},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 400)


class CuentaPropiaTests(FirestoreTestCase):
    def setUp(self):
        super().setUp()
        self.ana = self.crear_usuario(nombre='Ana', correo='ana.c@motolink.com')
        self.beto = self.crear_usuario(nombre='Beto', correo='beto.c@motolink.com')
        self.cliente_ana = self.cliente_de(self.ana)

    def test_no_se_puede_ver_la_ficha_ajena(self):
        respuesta = self.cliente_ana.get(f'/api/usuarios/{self.beto.id}/')
        self.assertEqual(respuesta.status_code, 403)

    def test_si_se_puede_ver_la_propia(self):
        respuesta = self.cliente_ana.get(f'/api/usuarios/{self.ana.id}/')
        self.assertEqual(respuesta.status_code, 200)

    def test_no_se_puede_editar_la_cuenta_ajena(self):
        respuesta = self.cliente_ana.patch(
            f'/api/usuarios/{self.beto.id}/', {'nombre': 'Hackeado'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 403)

    def test_nadie_se_puede_ascender_a_administrador(self):
        """Se rechaza de forma explícita, no en silencio: así quien lo
        intente recibe un error en vez de creer que funcionó."""
        respuesta = self.cliente_ana.patch(
            f'/api/usuarios/{self.ana.id}/',
            {'rol': RolUsuario.ADMINISTRADOR}, format='json',
        )
        self.assertEqual(respuesta.status_code, 400)
        self.assertEqual(
            self.usuarios.obtener_por_id(self.ana.id).rol, RolUsuario.PASAJERO,
        )

    def test_cambiar_el_nombre_sigue_funcionando(self):
        """La restricción del rol no debe estorbar la edición normal."""
        respuesta = self.cliente_ana.patch(
            f'/api/usuarios/{self.ana.id}/', {'nombre': 'Ana María'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 200)
        self.assertEqual(self.usuarios.obtener_por_id(self.ana.id).nombre, 'Ana María')

    def test_un_usuario_normal_no_puede_borrar_cuentas(self):
        respuesta = self.cliente_ana.delete(f'/api/usuarios/{self.beto.id}/')
        self.assertEqual(respuesta.status_code, 403)


class RegistroDeRolTests(FirestoreTestCase):
    """El registro es público: el rol no puede quedar a elección de quien
    se da de alta."""

    def setUp(self):
        super().setUp()
        self.anonimo = APIClient()

    def _registrar(self, rol, correo):
        return self.anonimo.post(
            '/api/usuarios/',
            {'nombre': 'X', 'correo': correo,
             'contrasena': 'MotoLink2026!', 'rol': rol},
            format='json',
        )

    def test_no_se_puede_registrar_un_administrador(self):
        """Agujero real: cualquiera se daba de alta como administrador
        desde la app y quedaba con permiso para listar y borrar cuentas,
        lo que dejaba sin efecto todos los permisos por rol."""
        respuesta = self._registrar(
            RolUsuario.ADMINISTRADOR, 'falso.admin@motolink.com',
        )
        self.assertEqual(respuesta.status_code, 400)
        self.assertIsNone(
            self.usuarios.buscar_por_correo('falso.admin@motolink.com'),
        )

    def test_los_roles_normales_si_se_pueden_registrar(self):
        self.assertEqual(
            self._registrar(RolUsuario.PASAJERO, 'p@motolink.com').status_code,
            201,
        )
        self.assertEqual(
            self._registrar(RolUsuario.MOTOTAXISTA, 'm@motolink.com').status_code,
            201,
        )

    def test_tampoco_por_la_via_del_alta_de_mototaxista(self):
        """El alta de mototaxista anida el usuario; la restricción debe
        aplicarse también ahí."""
        respuesta = self.anonimo.post(
            '/api/mototaxistas/',
            {'usuario': {'nombre': 'X', 'correo': 'falso2@motolink.com',
                         'contrasena': 'MotoLink2026!',
                         'rol': RolUsuario.ADMINISTRADOR},
             'licencia': 'L', 'placa': 'P', 'marca_vehiculo': 'M',
             'modelo_vehiculo': 'M'},
            format='json',
        )
        self.assertEqual(respuesta.status_code, 400)


class ContrasenaTests(FirestoreTestCase):
    """AUTH_PASSWORD_VALIDATORS estaba configurado pero no se aplicaba."""

    def setUp(self):
        super().setUp()
        self.anonimo = APIClient()

    def _registrar(self, contrasena):
        return self.anonimo.post(
            '/api/usuarios/',
            {'nombre': 'Test', 'correo': f'p{abs(hash(contrasena))}@motolink.com',
             'contrasena': contrasena, 'rol': 'pasajero'},
            format='json',
        )

    def test_se_rechaza_una_contrasena_demasiado_corta(self):
        self.assertEqual(self._registrar('1').status_code, 400)

    def test_se_rechaza_una_contrasena_solo_numerica(self):
        self.assertEqual(self._registrar('12345678').status_code, 400)

    def test_se_rechaza_una_contrasena_comun(self):
        self.assertEqual(self._registrar('password').status_code, 400)

    def test_se_acepta_una_contrasena_razonable(self):
        self.assertEqual(self._registrar('MotoLink2026!').status_code, 201)
