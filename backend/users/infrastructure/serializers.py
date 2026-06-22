from rest_framework import serializers

from .models import Mototaxista, Usuario


class UsuarioSerializer(serializers.ModelSerializer):
    class Meta:
        model = Usuario
        fields = ['id', 'nombre', 'correo', 'contrasena', 'rol']
        extra_kwargs = {'contrasena': {'write_only': True}}

    def create(self, validated_data):
        raw_password = validated_data.pop('contrasena')
        usuario = Usuario(**validated_data)
        usuario.set_password(raw_password)
        usuario.save()
        return usuario

    def update(self, instance, validated_data):
        raw_password = validated_data.pop('contrasena', None)
        for attr, value in validated_data.items():
            setattr(instance, attr, value)
        if raw_password:
            instance.set_password(raw_password)
        instance.save()
        return instance


class LoginSerializer(serializers.Serializer):
    correo = serializers.EmailField()
    contrasena = serializers.CharField(write_only=True)


class MototaxistaSerializer(serializers.ModelSerializer):
    usuario = UsuarioSerializer()

    class Meta:
        model = Mototaxista
        fields = ['usuario', 'licencia', 'placa', 'marca_vehiculo', 'modelo_vehiculo']

    def create(self, validated_data):
        usuario_data = validated_data.pop('usuario')
        raw_password = usuario_data.pop('contrasena')
        usuario = Usuario(**usuario_data)
        usuario.set_password(raw_password)
        usuario.save()
        return Mototaxista.objects.create(usuario=usuario, **validated_data)
