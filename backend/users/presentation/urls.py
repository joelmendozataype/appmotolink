from rest_framework.routers import DefaultRouter

from .views import MototaxistaViewSet, UsuarioViewSet

router = DefaultRouter()
router.register('usuarios', UsuarioViewSet, basename='usuario')
router.register('mototaxistas', MototaxistaViewSet, basename='mototaxista')

urlpatterns = router.urls
