"""Vistas de usuarios.

Pasan de ModelViewSet a ViewSet: sin ORM detrás, cada acción llama al
repositorio correspondiente. Las rutas, los cuerpos JSON y los códigos
de estado son los mismos que antes.
"""
from rest_framework import status
from rest_framework.decorators import action
from rest_framework.permissions import AllowAny, IsAuthenticated
from rest_framework.response import Response
from rest_framework.viewsets import ViewSet

from core import di
from core.authentication import SESSION_KEY
from users.domain.entities import RolUsuario
from users.domain.repositories import (
    MototaxistaNoEncontradoError,
    UsuarioNoEncontradoError,
)
from users.infrastructure.serializers import (
    LoginSerializer,
    MototaxistaSerializer,
    UsuarioSerializer,
)


def _no_encontrado():
    return Response({'detail': 'No encontrado.'}, status=status.HTTP_404_NOT_FOUND)


class UsuarioViewSet(ViewSet):
    serializer_class = UsuarioSerializer

    def get_permissions(self):
        if self.action in ('logout', 'me'):
            return [IsAuthenticated()]
        return [AllowAny()]

    def list(self, request):
        usuarios = di.usuario_repo().listar()
        return Response(UsuarioSerializer(usuarios, many=True).data)

    def retrieve(self, request, pk=None):
        try:
            usuario = di.usuario_repo().obtener_por_id(pk)
        except UsuarioNoEncontradoError:
            return _no_encontrado()
        return Response(UsuarioSerializer(usuario).data)

    def create(self, request):
        serializer = UsuarioSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        usuario = serializer.save()
        return Response(
            UsuarioSerializer(usuario).data, status=status.HTTP_201_CREATED,
        )

    def update(self, request, pk=None):
        return self._actualizar(request, pk, parcial=False)

    def partial_update(self, request, pk=None):
        return self._actualizar(request, pk, parcial=True)

    def _actualizar(self, request, pk, *, parcial):
        try:
            usuario = di.usuario_repo().obtener_por_id(pk)
        except UsuarioNoEncontradoError:
            return _no_encontrado()
        serializer = UsuarioSerializer(usuario, data=request.data, partial=parcial)
        serializer.is_valid(raise_exception=True)
        return Response(UsuarioSerializer(serializer.save()).data)

    def destroy(self, request, pk=None):
        try:
            di.usuario_repo().eliminar(pk)
        except UsuarioNoEncontradoError:
            return _no_encontrado()
        return Response(status=status.HTTP_204_NO_CONTENT)

    @action(detail=False, methods=['post'])
    def login(self, request):
        credenciales = LoginSerializer(data=request.data)
        credenciales.is_valid(raise_exception=True)

        usuario = di.usuario_repo().buscar_por_correo(
            credenciales.validated_data['correo'],
        )
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
        pasajeros = di.usuario_repo().listar(rol=RolUsuario.PASAJERO)
        return Response(UsuarioSerializer(pasajeros, many=True).data)


class MototaxistaViewSet(ViewSet):
    serializer_class = MototaxistaSerializer
    lookup_field = 'usuario_id'

    def list(self, request):
        mototaxistas = di.mototaxista_repo().listar()
        return Response(MototaxistaSerializer(mototaxistas, many=True).data)

    def retrieve(self, request, usuario_id=None):
        try:
            mototaxista = di.mototaxista_repo().obtener_por_id(usuario_id)
        except MototaxistaNoEncontradoError:
            return _no_encontrado()
        return Response(MototaxistaSerializer(mototaxista).data)

    def create(self, request):
        serializer = MototaxistaSerializer(data=request.data)
        serializer.is_valid(raise_exception=True)
        mototaxista = serializer.save()
        return Response(
            MototaxistaSerializer(mototaxista).data, status=status.HTTP_201_CREATED,
        )

    def update(self, request, usuario_id=None):
        return self._actualizar(request, usuario_id, parcial=False)

    def partial_update(self, request, usuario_id=None):
        return self._actualizar(request, usuario_id, parcial=True)

    def _actualizar(self, request, usuario_id, *, parcial):
        try:
            mototaxista = di.mototaxista_repo().obtener_por_id(usuario_id)
        except MototaxistaNoEncontradoError:
            return _no_encontrado()
        serializer = MototaxistaSerializer(
            mototaxista, data=request.data, partial=parcial,
        )
        serializer.is_valid(raise_exception=True)
        return Response(MototaxistaSerializer(serializer.save()).data)

    def destroy(self, request, usuario_id=None):
        try:
            di.mototaxista_repo().eliminar(usuario_id)
        except MototaxistaNoEncontradoError:
            return _no_encontrado()
        return Response(status=status.HTTP_204_NO_CONTENT)
