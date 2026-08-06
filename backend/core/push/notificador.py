"""Notificador que además de Socket.IO manda notificaciones push.

Envuelve al notificador de tiempo real en vez de sustituirlo: los dos
canales son complementarios. Socket.IO actualiza la pantalla de quien
tiene la app abierta; la push avisa a quien la tiene cerrada.

Los casos de uso no se enteran: siguen llamando a la misma interfaz.
"""
import logging

from core.push.dispositivos import FirestoreDispositivoRepository
from core.push.sender import FirebasePushSender
from core.realtime.notifier import SocketIORealtimeNotifier
from users.domain.entities import RolUsuario

logger = logging.getLogger('motolink.push')


class NotificadorConPush(SocketIORealtimeNotifier):
    def __init__(self, sender=None, dispositivos=None, usuario_repo=None):
        self._sender = sender or FirebasePushSender()
        self._dispositivos = dispositivos or FirestoreDispositivoRepository()
        self._usuario_repo = usuario_repo

    @property
    def usuario_repo(self):
        if self._usuario_repo is None:
            from core import di

            self._usuario_repo = di.usuario_repo()
        return self._usuario_repo

    def _avisar(self, tokens, titulo, cuerpo, datos=None):
        if not tokens:
            return
        for caducado in self._sender.enviar(tokens, titulo, cuerpo, datos):
            # El usuario desinstaló la app: se limpia para no seguir
            # intentándolo en cada aviso.
            self._dispositivos.eliminar(caducado)

    def _avisar_a(self, usuario_id, titulo, cuerpo, datos=None):
        self._avisar(
            self._dispositivos.tokens_de(usuario_id), titulo, cuerpo, datos,
        )

    def notificar_solicitud_creada(self, solicitud):
        super().notificar_solicitud_creada(solicitud)
        # A todos los mototaxistas: es el aviso que más falta hace con la
        # app cerrada, porque es el que trae trabajo.
        conductores = [
            u.id for u in self.usuario_repo.listar(rol=RolUsuario.MOTOTAXISTA)
        ]
        self._avisar(
            self._dispositivos.tokens_de_varios(conductores),
            'Nueva solicitud de viaje',
            f'{solicitud.origen} → {solicitud.destino} · '
            f'S/ {float(solicitud.tarifa_propuesta):.2f}',
            {'tipo': 'SolicitudCreada', 'solicitudId': solicitud.id},
        )

    def notificar_oferta_creada(self, oferta):
        super().notificar_oferta_creada(oferta)
        self._avisar_oferta(oferta, 'Un mototaxista aceptó tu tarifa')

    def notificar_contraoferta_creada(self, oferta):
        super().notificar_contraoferta_creada(oferta)
        self._avisar_oferta(oferta, 'Recibiste una contraoferta')

    def _avisar_oferta(self, oferta, titulo):
        if oferta.solicitud is None:
            return
        nombre = 'Un mototaxista'
        if oferta.conductor is not None and oferta.conductor.usuario:
            nombre = oferta.conductor.usuario.nombre
        self._avisar_a(
            oferta.solicitud.pasajero_id,
            titulo,
            f'{nombre} · S/ {float(oferta.tarifa):.2f}',
            {'tipo': 'OfertaCreada', 'solicitudId': oferta.solicitud_id},
        )

    def notificar_oferta_aceptada(self, oferta):
        super().notificar_oferta_aceptada(oferta)
        self._avisar_a(
            oferta.conductor_id,
            'Te seleccionaron',
            'Un pasajero eligió tu oferta. Ve a recogerlo.',
            {'tipo': 'OfertaAceptada', 'solicitudId': oferta.solicitud_id},
        )

    def notificar_viaje_asignado(self, viaje):
        super().notificar_viaje_asignado(viaje)
        self._avisar_a(
            viaje.conductor_id,
            'Viaje asignado',
            f'Tarifa acordada: S/ {float(viaje.tarifa_final):.2f}',
            {'tipo': 'ViajeAsignado', 'viajeId': viaje.id},
        )

    def notificar_viaje_finalizado(self, viaje):
        super().notificar_viaje_finalizado(viaje)
        # Sin push aquí: el viaje terminó bien y ambos suelen tener la app
        # delante. Una notificación del sistema sobraría.

    def notificar_viaje_cancelado(self, viaje):
        super().notificar_viaje_cancelado(viaje)
        # A las dos partes: quien canceló ya lo sabe, pero no se sabe cuál
        # de los dos fue, y enviarlo a ambos es inofensivo.
        for usuario_id in (viaje.pasajero_id, viaje.conductor_id):
            self._avisar_a(
                usuario_id,
                'Viaje cancelado',
                'El viaje fue cancelado.',
                {'tipo': 'ViajeCancelado', 'viajeId': viaje.id},
            )
