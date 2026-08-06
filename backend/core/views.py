from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
    throttle_classes,
)
from rest_framework.permissions import AllowAny
from rest_framework.response import Response


@api_view(['GET'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([])
def salud(request):
    """Comprobación de vida del servicio.

    Existe para el health check de la plataforma de despliegue, que marca
    el despliegue como fallido si no recibe un 2xx. El resto de la API
    exige sesión y devuelve 403, que Render interpreta como caída.

    A propósito no toca Firestore: responde si el proceso está vivo y
    atendiendo HTTP. Mezclar aquí el estado de la base de datos haría que
    una incidencia de Firestore tumbara el servicio entero en vez de
    degradarlo.

    Tampoco tiene throttling: el monitor que evita que la instancia
    gratuita se duerma la consulta cada pocos minutos.
    """
    return Response({'estado': 'ok', 'servicio': 'motolink-api'})
