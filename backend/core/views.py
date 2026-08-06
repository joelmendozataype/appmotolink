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
def portada(request):
    """Índice en la raíz del dominio.

    Sin esto, abrir el dominio a secas devuelve un 404 de Django que
    parece una avería cuando en realidad el servicio está bien: la API
    vive bajo /api/. Se limita a decir qué es esto y dónde mirar; no
    expone ningún dato ni ruta que requiera sesión.
    """
    return Response({
        'servicio': 'MotoLink API',
        'estado': 'ok',
        'documentacion': 'https://github.com/joelmendozataype/appmotolink',
        'salud': request.build_absolute_uri('/api/salud/'),
        'nota': (
            'El resto de la API requiere iniciar sesión y responde 403 sin '
            'ella. Eso es el comportamiento esperado, no un error.'
        ),
    })


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
