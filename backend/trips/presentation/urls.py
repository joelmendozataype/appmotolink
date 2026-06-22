from django.urls import path
from rest_framework.routers import DefaultRouter

from .views import HistorialView, SolicitudViajeViewSet, ViajeViewSet

router = DefaultRouter()
router.register('solicitudes-viaje', SolicitudViajeViewSet, basename='solicitud-viaje')
router.register('viajes', ViajeViewSet, basename='viaje')

urlpatterns = router.urls + [
    path('historial/', HistorialView.as_view({'get': 'list'}), name='historial'),
]
