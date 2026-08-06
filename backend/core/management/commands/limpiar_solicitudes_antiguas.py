"""Cancela solicitudes abiertas que ya nadie va a atender.

    python manage.py limpiar_solicitudes_antiguas --dry-run
    python manage.py limpiar_solicitudes_antiguas

Las solicitudes migradas desde SQLite se quedaron en 'pendiente' para
siempre: nunca se aceptaron ni se cancelaron, porque hasta hace poco no
existía forma de cancelarlas. Siguen apareciéndole al conductor en
"Solicitudes disponibles" y ensucian la lista sin aportar nada.

Se cancelan, no se borran: el registro se conserva y solo deja de
mostrarse como disponible. Si hiciera falta revertirlo, basta con
devolver el estado a 'pendiente'.

El criterio por defecto es la ausencia de fecha de creación, que es
exactamente lo que distingue a los registros anteriores a que se
empezaran a sellar. Con --antes-de se puede usar una fecha concreta.
"""
from datetime import datetime, timezone

from django.core.management.base import BaseCommand

from core import di
from trips.domain.entities import EstadoSolicitud

ABIERTAS = (EstadoSolicitud.PENDIENTE, EstadoSolicitud.EN_NEGOCIACION)


class Command(BaseCommand):
    help = 'Cancela solicitudes abiertas que quedaron huérfanas.'

    def add_arguments(self, parser):
        parser.add_argument(
            '--dry-run', action='store_true',
            help='Muestra cuáles se cancelarían, sin tocar nada.',
        )
        parser.add_argument(
            '--antes-de', default=None,
            help='Fecha ISO (2026-08-01). Por defecto, solo las que no '
                 'tienen fecha de creación.',
        )

    def handle(self, *args, **opciones):
        simulacion = opciones['dry_run']
        limite = None
        if opciones['antes_de']:
            limite = datetime.fromisoformat(opciones['antes_de'])
            if limite.tzinfo is None:
                limite = limite.replace(tzinfo=timezone.utc)

        repo = di.solicitud_repo()
        candidatas = [
            s for s in repo.listar()
            if s.estado in ABIERTAS and self._es_antigua(s, limite)
        ]

        if not candidatas:
            self.stdout.write('No hay solicitudes que limpiar.')
            return

        self.stdout.write(f'{len(candidatas)} solicitudes a cancelar:\n')
        for s in candidatas:
            fecha = s.creado_en.date() if s.creado_en else 'sin fecha'
            self.stdout.write(
                f'  [{s.estado:<13}] {fecha}  {s.origen[:28]} -> {s.destino[:28]}',
            )

        if simulacion:
            self.stdout.write(self.style.WARNING(
                '\nModo --dry-run: no se canceló ninguna. Repite el comando '
                'sin --dry-run para aplicarlo.',
            ))
            return

        canceladas = 0
        for s in candidatas:
            # Cambio condicional: si alguien la aceptó entre el listado y
            # ahora, no se pisa esa decisión.
            if repo.cerrar_si_disponible(s.id, ABIERTAS, EstadoSolicitud.CANCELADA):
                canceladas += 1

        self.stdout.write(self.style.SUCCESS(
            f'\n{canceladas} solicitudes canceladas.',
        ))
        if canceladas != len(candidatas):
            self.stdout.write(self.style.WARNING(
                f'{len(candidatas) - canceladas} cambiaron de estado mientras '
                'se ejecutaba y se dejaron como estaban.',
            ))

    @staticmethod
    def _es_antigua(solicitud, limite):
        if limite is None:
            return solicitud.creado_en is None
        return solicitud.creado_en is None or solicitud.creado_en < limite
