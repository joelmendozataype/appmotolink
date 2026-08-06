from django.urls import path
from rest_framework.routers import DefaultRouter

from users.presentation.recuperacion_views import recuperar, restablecer

from .views import MototaxistaViewSet, UsuarioViewSet

router = DefaultRouter()
router.register('usuarios', UsuarioViewSet, basename='usuario')
router.register('mototaxistas', MototaxistaViewSet, basename='mototaxista')

# Estas dos van ANTES del router: si no, la ruta genérica usuarios/<id>/
# captura "recuperar" como si fuera un identificador de usuario y exige
# sesión, devolviendo 403 en vez de atender la petición.
urlpatterns = [
    path('usuarios/recuperar/', recuperar, name='recuperar'),
    path('usuarios/restablecer/', restablecer, name='restablecer'),
] + router.urls
