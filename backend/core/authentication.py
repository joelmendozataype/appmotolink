from rest_framework.authentication import BaseAuthentication

from users.infrastructure.models import Usuario

SESSION_KEY = 'usuario_id'


class SesionUsuarioAuthentication(BaseAuthentication):
    """Autenticación básica por sesión sobre el modelo Usuario (sin JWT)."""

    def authenticate(self, request):
        usuario_id = request.session.get(SESSION_KEY)
        if not usuario_id:
            return None
        try:
            usuario = Usuario.objects.get(id=usuario_id, is_active=True)
        except Usuario.DoesNotExist:
            return None
        return (usuario, None)
