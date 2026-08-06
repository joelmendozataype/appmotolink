"""Límites de frecuencia.

El límite del login por IP resultó no funcionar en producción: doce
intentos fallidos seguidos contra la cuenta de administrador pasaron sin
bloqueo, mientras que en local se cortaban al undécimo. Detrás del proxy
de Render, DRF identifica al cliente anónimo a partir de
`X-Forwarded-For`, y si esa cadena varía entre peticiones cada una cae en
un contador distinto.

La respuesta no es solo arreglar la detección de IP —que también, ver
NUM_PROXIES en settings—, sino cambiar de criterio: lo que interesa
proteger es *la cuenta*, no *el origen*. Un atacante puede rotar de IP
con facilidad; lo que no puede cambiar es a quién quiere entrar.
"""
from rest_framework.throttling import SimpleRateThrottle


class LoginPorCuentaThrottle(SimpleRateThrottle):
    """Limita los intentos de login contra un mismo correo.

    Cuenta por cuenta atacada y no por origen, así que resiste a que el
    atacante cambie de IP o esté detrás de un proxy compartido.

    Solo cuenta los intentos anónimos de inicio de sesión; el resto de
    rutas no pasa por aquí.
    """

    scope = 'login'

    def get_cache_key(self, request, view):
        correo = ''
        if isinstance(request.data, dict):
            correo = str(request.data.get('correo', '')).strip().lower()
        if not correo:
            # Sin correo no hay cuenta que proteger; la validación del
            # serializer rechazará la petición de todos modos.
            return None
        return f'throttle_login_cuenta_{correo}'


class LoginPorOrigenThrottle(SimpleRateThrottle):
    """Segunda barrera, por origen: frena a quien prueba muchas cuentas
    distintas desde el mismo sitio, que la barrera por cuenta no ve.

    Es la que depende de acertar la IP real del cliente, de ahí que
    convivan las dos.
    """

    scope = 'login_origen'

    def get_cache_key(self, request, view):
        return self.cache_format % {
            'scope': self.scope,
            'ident': self.get_ident(request),
        }
