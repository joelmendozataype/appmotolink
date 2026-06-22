from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ModelViewSet

from core.authentication import SESSION_KEY
from users.infrastructure.models import Mototaxista, RolUsuario, Usuario
from users.infrastructure.serializers import (
    LoginSerializer,
    MototaxistaSerializer,
    UsuarioSerializer,
)


class UsuarioViewSet(ModelViewSet):
    queryset = Usuario.objects.all()
    serializer_class = UsuarioSerializer

    def get_permissions(self):
        if self.action in ('logout', 'me'):
            return [IsAuthenticated()]
        return [AllowAny()]

    @action(detail=False, methods=['post'])
    def login(self, request):
        credenciales = LoginSerializer(data=request.data)
        credenciales.is_valid(raise_exception=True)

        usuario = Usuario.objects.filter(
            correo=credenciales.validated_data['correo'],
        ).first()
        if usuario is None or not usuario.check_password(
            credenciales.validated_data['contrasena'],
        ):
            return Response(
                {'detail': 'Credenciales inválidas'},
                status=status.HTTP_401_UNAUTHORIZED,
            )

        request.session[SESSION_KEY] = str(usuario.id)
        return Response(UsuarioSerializer(usuario).data)

    @action(detail=False, methods=['post'])
    def logout(self, request):
        request.session.pop(SESSION_KEY, None)
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['get'])
    def me(self, request):
        return Response(UsuarioSerializer(request.user).data)

    @action(detail=False, methods=['get'])
    def pasajeros(self, request):
        pasajeros = Usuario.objects.filter(rol=RolUsuario.PASAJERO)
        return Response(UsuarioSerializer(pasajeros, many=True).data)


class MototaxistaViewSet(ModelViewSet):
    queryset = Mototaxista.objects.all()
    serializer_class = MototaxistaSerializer
    lookup_field = 'usuario_id'
