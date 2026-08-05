from rest_framework.authentication import BaseAuthentication

from core import di
from users.domain.repositories import UsuarioNoEncontradoError

SESSION_KEY = 'usuario_id'


class SesionUsuarioAuthentication(BaseAuthentication):
    """Autenticación básica por sesión sobre la entidad Usuario (sin JWT).

    La sesión ahora viaja en una cookie firmada y el usuario se lee de
    Firestore: autenticarse ya no toca ninguna base de datos SQL.
    """

    def authenticate(self, request):
        usuario_id = request.session.get(SESSION_KEY)
        if not usuario_id:
            return None
        try:
            usuario = di.usuario_repo().obtener_por_id(usuario_id)
        except UsuarioNoEncontradoError:
            return None
        if not usuario.is_active:
            return None
        return (usuario, None)
