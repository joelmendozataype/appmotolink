"""Recuperación de contraseña: pedir código y restablecer."""
import logging

from django.conf import settings
from django.core.mail import send_mail
from rest_framework import serializers, status
from rest_framework.decorators import (
    api_view,
    authentication_classes,
    permission_classes,
    throttle_classes,
)
from rest_framework.permissions import AllowAny
from rest_framework.response import Response
from rest_framework.throttling import SimpleRateThrottle

from core import di
from users.domain.recuperacion import CodigoRecuperacion, generar_codigo
from users.infrastructure.recuperacion_repository import RecuperacionRepository
from users.infrastructure.serializers import _validar_contrasena

logger = logging.getLogger('motolink.recuperacion')

MENSAJE_GENERICO = (
    'Si el correo está registrado, recibirás un código para restablecer '
    'tu contraseña.'
)


class _RecuperarThrottle(SimpleRateThrottle):
    """Por cuenta, igual que el login.

    Sin esto, esta ruta sería un modo cómodo de saber qué correos existen
    —aunque la respuesta sea genérica— y de llenarle el buzón a alguien.
    """

    scope = 'recuperar'

    def get_cache_key(self, request, view):
        correo = ''
        if isinstance(request.data, dict):
            correo = str(request.data.get('correo', '')).strip().lower()
        return f'throttle_recuperar_{correo}' if correo else None


class _SolicitudSerializer(serializers.Serializer):
    correo = serializers.EmailField()


class _RestablecerSerializer(serializers.Serializer):
    correo = serializers.EmailField()
    codigo = serializers.CharField(max_length=10)
    contrasena = serializers.CharField(max_length=255)

    def validate_contrasena(self, valor):
        return _validar_contrasena(valor)


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
@throttle_classes([_RecuperarThrottle])
def recuperar(request):
    """Envía un código de un solo uso al correo indicado.

    Responde lo mismo exista o no la cuenta: si dijera "ese correo no está
    registrado", cualquiera podría averiguar quién tiene cuenta probando
    direcciones.
    """
    datos = _SolicitudSerializer(data=request.data)
    datos.is_valid(raise_exception=True)
    correo = datos.validated_data['correo']

    usuario = di.usuario_repo().buscar_por_correo(correo)
    if usuario is not None and usuario.is_active:
        codigo = generar_codigo()
        RecuperacionRepository().guardar(
            correo, CodigoRecuperacion.nuevo(usuario.id, codigo),
        )
        _enviar(correo, usuario.nombre, codigo)

    return Response({'detail': MENSAJE_GENERICO})


def _enviar(correo, nombre, codigo):
    cuerpo = (
        f'Hola {nombre}:\n\n'
        f'Tu código para restablecer la contraseña de MotoLink es:\n\n'
        f'    {codigo}\n\n'
        'Caduca en 15 minutos y solo se puede usar una vez.\n\n'
        'Si no pediste este cambio, ignora este mensaje: tu contraseña '
        'actual sigue siendo válida.\n'
    )
    try:
        send_mail(
            'Código para restablecer tu contraseña · MotoLink',
            cuerpo,
            settings.DEFAULT_FROM_EMAIL,
            [correo],
            fail_silently=False,
        )
    except Exception as error:
        # Que el correo no salga no debe delatar si la cuenta existe, así
        # que la respuesta al cliente no cambia; queda en el log para
        # poder diagnosticarlo.
        logger.error('No se pudo enviar el código a %s: %s', correo, error)


@api_view(['POST'])
@authentication_classes([])
@permission_classes([AllowAny])
def restablecer(request):
    """Canjea el código por una contraseña nueva."""
    datos = _RestablecerSerializer(data=request.data)
    datos.is_valid(raise_exception=True)
    correo = datos.validated_data['correo']

    repo = RecuperacionRepository()
    codigo = repo.buscar(correo)
    invalido = Response(
        {'detail': 'El código no es válido o ya caducó. Pide uno nuevo.'},
        status=status.HTTP_400_BAD_REQUEST,
    )

    if codigo is None or codigo.caducado or codigo.agotado:
        # Se limpia lo que ya no sirve para no dejar códigos muertos.
        if codigo is not None:
            repo.eliminar(correo)
        return invalido

    if not codigo.coincide(datos.validated_data['codigo']):
        repo.registrar_intento_fallido(correo, codigo)
        return invalido

    usuario_repo = di.usuario_repo()
    usuario = usuario_repo.buscar_por_correo(correo)
    if usuario is None:
        repo.eliminar(correo)
        return invalido

    usuario.set_password(datos.validated_data['contrasena'])
    usuario_repo.guardar(usuario)
    # De un solo uso: se borra en cuanto se canjea.
    repo.eliminar(correo)

    return Response({'detail': 'Contraseña actualizada. Ya puedes entrar.'})
