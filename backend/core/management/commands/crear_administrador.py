"""Crea o promueve una cuenta de administrador de MotoLink.

El registro público no permite elegir el rol 'administrador' —si lo
permitiera, cualquiera se daría de alta con permiso para listar y borrar
cuentas—, así que los administradores se crean por aquí:

    python manage.py crear_administrador --correo admin@motolink.com

La contraseña se pide por teclado y no se muestra ni queda en el
historial del terminal.
"""
from getpass import getpass

from django.core.management.base import BaseCommand, CommandError

from core import di
from users.domain.entities import RolUsuario, Usuario
from users.domain.repositories import CorreoDuplicadoError


class Command(BaseCommand):
    help = 'Crea un administrador, o promueve a administrador una cuenta existente.'

    def add_arguments(self, parser):
        parser.add_argument('--correo', required=True)
        parser.add_argument(
            '--nombre', default='Administrador',
            help='Solo se usa si la cuenta no existe todavía.',
        )

    def handle(self, *args, **opciones):
        correo = opciones['correo'].strip()
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
        if len(contrasena) < 8:
            raise CommandError('Usa al menos 8 caracteres.')

        nuevo = Usuario(
            nombre=opciones['nombre'], correo=correo,
            rol=RolUsuario.ADMINISTRADOR,
        )
        nuevo.set_password(contrasena)
        try:
            repo.crear(nuevo)
        except CorreoDuplicadoError as error:
            raise CommandError(f'Ya existe una cuenta con {correo}.') from error

        self.stdout.write(self.style.SUCCESS(
            f'Administrador creado: {correo}',
        ))
