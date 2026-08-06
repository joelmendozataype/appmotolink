"""Serializers de usuarios.

Ya no son ModelSerializer (no hay modelos Django detrás), pero el JSON
de entrada y de salida es exactamente el mismo que antes: la app Flutter
no se entera de que la persistencia cambió.
"""
from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from rest_framework import serializers

from core import di
from users.domain.entities import Mototaxista, RolUsuario, Usuario
from users.domain.repositories import CorreoDuplicadoError

CORREO_DUPLICADO = 'Ya existe un usuario con este correo.'


def _validar_contrasena(valor):
    """Aplica AUTH_PASSWORD_VALIDATORS al registro.

    Estaban configurados en settings pero nadie los invocaba, así que se
    aceptaba cualquier cosa como contraseña, incluida '1'.
    """
    try:
        validate_password(valor)
    except DjangoValidationError as error:
        raise serializers.ValidationError(list(error.messages))
    return valor


class UsuarioSerializer(serializers.Serializer):
    id = serializers.CharField(read_only=True)
    nombre = serializers.CharField(max_length=150)
    correo = serializers.EmailField()
    contrasena = serializers.CharField(max_length=255, write_only=True)
    rol = serializers.ChoiceField(choices=RolUsuario.valores())

    def validate_contrasena(self, valor):
        return _validar_contrasena(valor)

    def validate_rol(self, valor):
        """El registro es público, así que el rol no puede ser libre.

        Sin esto, cualquiera se daba de alta desde la app eligiendo
        'administrador' y quedaba con permiso para listar y borrar
        cuentas, lo que dejaba sin efecto todos los permisos por rol.

        Los administradores se crean fuera de banda:
            python manage.py crear_administrador
        """
        if valor == RolUsuario.ADMINISTRADOR:
            raise serializers.ValidationError(
                'No es posible registrarse como administrador.',
            )
        return valor

    def create(self, validated_data):
        usuario = Usuario(
            nombre=validated_data['nombre'],
            correo=validated_data['correo'],
            rol=validated_data['rol'],
        )
        usuario.set_password(validated_data['contrasena'])
        try:
            return di.usuario_repo().crear(usuario)
        except CorreoDuplicadoError:
            raise serializers.ValidationError({'correo': [CORREO_DUPLICADO]})

    def update(self, instance, validated_data):
        raw_password = validated_data.pop('contrasena', None)
        # El rol nunca se cambia por esta vía: si no, cualquiera podría
        # ascenderse a administrador editando su propia ficha.
        validated_data.pop('rol', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if raw_password:
            instance.set_password(raw_password)
        try:
            return di.usuario_repo().guardar(instance)
        except CorreoDuplicadoError:
            raise serializers.ValidationError({'correo': [CORREO_DUPLICADO]})


class LoginSerializer(serializers.Serializer):
    correo = serializers.EmailField()
    contrasena = serializers.CharField(write_only=True)


class MototaxistaSerializer(serializers.Serializer):
    usuario = UsuarioSerializer()
    licencia = serializers.CharField(max_length=50)
    placa = serializers.CharField(max_length=20)
    marca_vehiculo = serializers.CharField(max_length=50)
    modelo_vehiculo = serializers.CharField(max_length=50)

    def create(self, validated_data):
        usuario_data = validated_data.pop('usuario')
        usuario = Usuario(
            nombre=usuario_data['nombre'],
            correo=usuario_data['correo'],
            rol=usuario_data['rol'],
        )
        usuario.set_password(usuario_data['contrasena'])
        try:
            di.usuario_repo().crear(usuario)
        except CorreoDuplicadoError:
            raise serializers.ValidationError(
                {'usuario': {'correo': [CORREO_DUPLICADO]}},
            )

        mototaxista = Mototaxista(
            usuario_id=usuario.id, usuario=usuario, **validated_data,
        )
        return di.mototaxista_repo().crear(mototaxista)

    def update(self, instance, validated_data):
        validated_data.pop('usuario', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        return di.mototaxista_repo().guardar(instance)
