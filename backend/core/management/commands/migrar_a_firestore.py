"""Migra los datos de MotoLink desde db.sqlite3 hacia Cloud Firestore.

    python manage.py migrar_a_firestore --dry-run     # solo informa
    python manage.py migrar_a_firestore               # migra de verdad

Lee SQLite con el módulo `sqlite3` de la biblioteca estándar, no con el
ORM: los modelos de Django ya no existen, y así el script sigue
funcionando aunque la base vieja quede congelada.

Es idempotente: cada documento se escribe con un id derivado del dato
original, de modo que volver a correrlo reescribe los mismos documentos
en vez de duplicarlos.
"""
import sqlite3
import uuid
from decimal import Decimal
from pathlib import Path

from django.conf import settings
from django.core.management.base import BaseCommand, CommandError

from core.firestore import get_store
from core.firestore.colecciones import (
    CALIFICACIONES,
    MOTOTAXISTAS,
    OFERTAS,
    SOLICITUDES,
    USUARIOS,
    VIAJES,
)
from negotiation.domain.entities import id_documento
from ratings.infrastructure.firestore_repositories import INDICE_POR_VIAJE
from users.infrastructure.firestore_repositories import CORREOS, _clave_correo


def _uuid_canonico(valor):
    """Django guardaba los UUID como 32 hex sin guiones; se normalizan a
    la forma canónica con guiones, que es la que generan las entidades."""
    if valor is None:
        return None
    texto = str(valor)
    try:
        return str(uuid.UUID(texto))
    except (ValueError, AttributeError):
        return texto


def _fecha(valor):
    """SQLite guarda las fechas como texto ISO."""
    if valor is None:
        return None
    from core.firestore.campos import a_datetime

    try:
        return a_datetime(valor.replace(' ', 'T') if isinstance(valor, str) else valor)
    except ValueError:
        return None


def _float(valor):
    return float(Decimal(str(valor))) if valor is not None else 0.0


class Command(BaseCommand):
    help = 'Migra usuarios, viajes, ofertas y calificaciones de SQLite a Firestore.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--sqlite',
            default=str(Path(settings.BASE_DIR) / 'db.sqlite3'),
            help='Ruta al archivo db.sqlite3 de origen.',
        )
        parser.add_argument(
            '--dry-run',
            action='store_true',
            help='Cuenta y valida los registros sin escribir nada en Firestore.',
        )

    def handle(self, *args, **opciones):
        origen = Path(opciones['sqlite'])
        if not origen.exists():
            raise CommandError(f'No existe el archivo SQLite: {origen}')

        simulacion = opciones['dry_run']
        conexion = sqlite3.connect(str(origen))
        conexion.row_factory = sqlite3.Row
        store = None if simulacion else get_store()

        if simulacion:
            self.stdout.write(self.style.WARNING(
                'Modo --dry-run: no se escribe nada en Firestore.',
            ))
        else:
            destino = getattr(settings, 'MOTOLINK_DB_BACKEND', 'firestore')
            self.stdout.write(f'Destino: MOTOLINK_DB_BACKEND={destino}')

        try:
            totales = {
                'usuarios': self._migrar_usuarios(conexion, store),
                'mototaxistas': self._migrar_mototaxistas(conexion, store),
                'solicitudes_viaje': self._migrar_solicitudes(conexion, store),
                'viajes': self._migrar_viajes(conexion, store),
                'ofertas': self._migrar_ofertas(conexion, store),
                'calificaciones': self._migrar_calificaciones(conexion, store),
            }
        finally:
            conexion.close()

        self.stdout.write('')
        self.stdout.write(self.style.SUCCESS('Resumen de la migración:'))
        for coleccion, cantidad in totales.items():
            self.stdout.write(f'  {coleccion:<22} {cantidad}')
        if simulacion:
            self.stdout.write(self.style.WARNING(
                '\nNada fue escrito. Repite el comando sin --dry-run para migrar.',
            ))

    def _filas(self, conexion, tabla):
        try:
            return conexion.execute(f'SELECT * FROM "{tabla}"').fetchall()
        except sqlite3.OperationalError:
            self.stdout.write(self.style.WARNING(
                f'  (la tabla {tabla} no existe en el SQLite de origen; se omite)',
            ))
            return []

    def _escribir(self, store, coleccion, doc_id, datos):
        if store is not None:
            store.set(coleccion, doc_id, datos)

    def _migrar_usuarios(self, conexion, store):
        total = 0
        for fila in self._filas(conexion, 'users_usuario'):
            usuario_id = _uuid_canonico(fila['id'])
            correo = fila['correo']
            self._escribir(store, USUARIOS, usuario_id, {
                'nombre': fila['nombre'],
                'correo': correo,
                # El hash de Django se copia tal cual: nadie tiene que
                # cambiar su contraseña por la migración.
                'contrasena': fila['contrasena'],
                'rol': fila['rol'],
                'is_active': bool(fila['is_active']),
            })
            # Índice que reemplaza al UNIQUE(correo) de SQLite.
            self._escribir(store, CORREOS, _clave_correo(correo), {
                'usuario_id': usuario_id,
            })
            total += 1
        self.stdout.write(f'usuarios: {total}')
        return total

    def _migrar_mototaxistas(self, conexion, store):
        total = 0
        for fila in self._filas(conexion, 'users_mototaxista'):
            self._escribir(store, MOTOTAXISTAS, _uuid_canonico(fila['usuario_id']), {
                'licencia': fila['licencia'],
                'placa': fila['placa'],
                'marca_vehiculo': fila['marca_vehiculo'],
                'modelo_vehiculo': fila['modelo_vehiculo'],
            })
            total += 1
        self.stdout.write(f'mototaxistas: {total}')
        return total

    def _migrar_solicitudes(self, conexion, store):
        total = 0
        for fila in self._filas(conexion, 'trips_solicitudviaje'):
            self._escribir(store, SOLICITUDES, _uuid_canonico(fila['id']), {
                'pasajero_id': _uuid_canonico(fila['pasajero_id']),
                'origen': fila['origen'],
                'destino': fila['destino'],
                'tarifa_propuesta': _float(fila['tarifa_propuesta']),
                'estado': fila['estado'],
            })
            total += 1
        self.stdout.write(f'solicitudes_viaje: {total}')
        return total

    def _migrar_viajes(self, conexion, store):
        total = 0
        for fila in self._filas(conexion, 'trips_viaje'):
            self._escribir(store, VIAJES, _uuid_canonico(fila['id']), {
                'solicitud_id': _uuid_canonico(fila['solicitud_id']),
                'pasajero_id': _uuid_canonico(fila['pasajero_id']),
                'conductor_id': _uuid_canonico(fila['conductor_id']),
                'tarifa_final': _float(fila['tarifa_final']),
                'estado': fila['estado'],
            })
            total += 1
        self.stdout.write(f'viajes: {total}')
        return total

    def _migrar_ofertas(self, conexion, store):
        """Las ofertas se RE-INDEXAN: su id pasa a derivarse de la pareja
        (solicitud, conductor). Así la unicidad que daba la UNIQUE
        constraint de SQLite se mantiene en Firestore."""
        total = 0
        for fila in self._filas(conexion, 'negotiation_oferta'):
            solicitud_id = _uuid_canonico(fila['solicitud_id'])
            conductor_id = _uuid_canonico(fila['conductor_id'])
            self._escribir(store, OFERTAS, id_documento(solicitud_id, conductor_id), {
                'solicitud_id': solicitud_id,
                'conductor_id': conductor_id,
                'tarifa': _float(fila['tarifa']),
                'tipo': fila['tipo'],
                'estado': fila['estado'],
                'fecha': _fecha(fila['fecha']),
            })
            total += 1
        self.stdout.write(f'ofertas: {total} (re-indexadas por solicitud+conductor)')
        return total

    def _migrar_calificaciones(self, conexion, store):
        total = 0
        for fila in self._filas(conexion, 'ratings_calificacion'):
            calificacion_id = _uuid_canonico(fila['id'])
            viaje_id = _uuid_canonico(fila['viaje_id'])
            puntuacion = int(fila['puntuacion'])
            if not 1 <= puntuacion <= 5:
                # El CHECK de SQLite solo exigía >= 0; si aparece un 0 se
                # avisa y se deja fuera en vez de migrar un dato inválido.
                self.stdout.write(self.style.WARNING(
                    f'  calificación {calificacion_id} omitida: '
                    f'puntuación {puntuacion} fuera del rango 1..5',
                ))
                continue
            self._escribir(store, CALIFICACIONES, calificacion_id, {
                'viaje_id': viaje_id,
                'puntuacion': puntuacion,
                'comentario': fila['comentario'] or '',
                'fecha': _fecha(fila['fecha']),
            })
            # Índice que reemplaza al OneToOneField(viaje).
            self._escribir(store, INDICE_POR_VIAJE, viaje_id, {
                'calificacion_id': calificacion_id,
            })
            total += 1
        self.stdout.write(f'calificaciones: {total}')
        return total
