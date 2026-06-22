from rest_framework.routers import DefaultRouter

from .views import OfertaViewSet

router = DefaultRouter()
router.register('ofertas', OfertaViewSet, basename='oferta')

urlpatterns = router.urls
