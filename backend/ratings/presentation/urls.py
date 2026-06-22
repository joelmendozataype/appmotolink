from rest_framework.routers import DefaultRouter

from .views import CalificacionViewSet

router = DefaultRouter()
router.register('calificaciones', CalificacionViewSet, basename='calificacion')

urlpatterns = router.urls
