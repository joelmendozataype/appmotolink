"""Crea o promueve una cuenta de administrador de MotoLink.

El registro público no permite elegir el rol 'administrador' —si lo
permitiera, cualquiera se daría de alta con permiso para listar y borrar
cuentas—, así que los administradores se crean por aquí:

    python manage.py crear_administrador --correo admin@motolink.com

La contraseña se pide por teclado y no se muestra ni queda en el
historial del terminal.
"""
from getpass import getpass

from django.contrib.auth.password_validation import validate_password
from django.core.exceptions import ValidationError as DjangoValidationError
from django.core.management.base import BaseCommand, CommandError

from core import di
from users.domain.entities import RolUsuario, Usuario
from users.domain.repositories import CorreoDuplicadoError
from users.domain.validaciones import (
    DatoInvalidoError,
    validar_correo,
    validar_nombre,
)


class Command(BaseCommand):
    help = 'Crea un administrador, o promueve a administrador una cuenta existente.'

    def add_arguments(self, parser):
        parser.add_argument('--correo', required=True)
        parser.add_argument(
            '--nombre', default='Administrador',
            help='Solo se usa si la cuenta no existe todavía.',
        )

    def handle(self, *args, **opciones):
        # Se valida antes de pedir la contraseña: si el correo está mal
        # escrito, es una tontería hacer teclearla dos veces para nada.
        # Son las mismas reglas que aplica el registro de pasajeros y
        # mototaxistas; el administrador no es una excepción.
        try:
            correo = validar_correo(opciones['correo'])
            nombre = validar_nombre(opciones['nombre'])
        except DatoInvalidoError as error:
            raise CommandError(str(error)) from error

        repo = di.usuario_repo()
        usuario = repo.buscar_por_correo(correo)

        if usuario is not None:
            if usuario.rol == RolUsuario.ADMINISTRADOR:
                self.stdout.write(f'{correo} ya es administrador.')
                return
            anterior = usuario.rol
            usuario.rol = RolUsuario.ADMINISTRADOR
            repo.guardar(usuario)
            self.stdout.write(self.style.SUCCESS(
                f'{correo} promovido de {anterior} a administrador.',
            ))
            return

        contrasena = getpass('Contraseña para el nuevo administrador: ')
        if contrasena != getpass('Repite la contraseña: '):
            raise CommandError('Las contraseñas no coinciden.')
        # Los mismos validadores que el registro público, en vez de un
        # mínimo de 8 caracteres a mano: antes esta vía admitía
        # contraseñas que la API habría rechazado.
        try:
            validate_password(contrasena)
        except DjangoValidationError as error:
            raise CommandError(' '.join(error.messages)) from error

        nuevo = Usuario(
            nombre=nombre, correo=correo, rol=RolUsuario.ADMINISTRADOR,
        )
        nuevo.set_password(contrasena)
        try:
            repo.crear(nuevo)
        except CorreoDuplicadoError as error:
            raise CommandError(f'Ya existe una cuenta con {correo}.') from error

        self.stdout.write(self.style.SUCCESS(
            f'Administrador creado: {correo}',
        ))
