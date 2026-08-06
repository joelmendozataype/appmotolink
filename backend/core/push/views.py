from rest_framework import serializers, status
from rest_framework.decorators import api_view, permission_classes
from rest_framework.permissions import IsAuthenticated
from rest_framework.response import Response

from core.push.dispositivos import FirestoreDispositivoRepository


class _TokenSerializer(serializers.Serializer):
    token = serializers.CharField(max_length=4096)


@api_view(['POST', 'DELETE'])
@permission_classes([IsAuthenticated])
def dispositivo(request):
    """Registra o da de baja el dispositivo del usuario en sesión.

    POST al iniciar sesión, DELETE al cerrarla: si no se diera de baja,
    el teléfono seguiría recibiendo avisos de una cuenta que ya no está
    usando, algo especialmente incómodo en un aparato compartido.

    El usuario sale de la sesión, nunca del cuerpo: si no, cualquiera
    podría redirigir las notificaciones de otro a su propio teléfono.
    """
    datos = _TokenSerializer(data=request.data)
    datos.is_valid(raise_exception=True)
    token = datos.validated_data['token']
    repo = FirestoreDispositivoRepository()

    if request.method == 'DELETE':
        repo.eliminar(token)
        return Response(status=status.HTTP_204_NO_CONTENT)

    repo.registrar(request.user.id, token)
    return Response({'estado': 'registrado'}, status=status.HTTP_201_CREATED)
