from rest_framework.viewsets import ModelViewSet

from ratings.infrastructure.models import Calificacion
from ratings.infrastructure.serializers import CalificacionSerializer


class CalificacionViewSet(ModelViewSet):
    queryset = Calificacion.objects.all()
    serializer_class = CalificacionSerializer
    http_method_names = ['get', 'post']
