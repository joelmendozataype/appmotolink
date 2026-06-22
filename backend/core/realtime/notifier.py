from abc import ABC, abstractmethod

from core.realtime.events import RealtimeEvents, room_conductores, room_solicitud, room_usuario
from core.realtime.server import sio


class RealtimeNotifier(ABC):
    """Puerto de dominio: los casos de uso dependen de esta interfaz, no de
    Socket.IO directamente (Clean Architecture)."""

    @abstractmethod
    def notificar_solicitud_creada(self, solicitud):
        ...

    @abstractmethod
    def notificar_oferta_creada(self, oferta):
        ...

    @abstractmethod
    def notificar_contraoferta_creada(self, oferta):
        ...

    @abstractmethod
    def notificar_oferta_aceptada(self, oferta):
        ...

    @abstractmethod
    def notificar_viaje_asignado(self, viaje):
        ...


def _payload_solicitud(solicitud):
    return {
        'id': str(solicitud.id),
        'pasajeroId': str(solicitud.pasajero_id),
        'origen': solicitud.origen,
        'destino': solicitud.destino,
        'tarifaPropuesta': float(solicitud.tarifa_propuesta),
        'estado': solicitud.estado,
    }


def _payload_oferta(oferta):
    return {
        'id': str(oferta.id),
        'solicitudId': str(oferta.solicitud_id),
        'conductorId': str(oferta.conductor_id),
        'conductorNombre': oferta.conductor.usuario.nombre,
        'tarifa': float(oferta.tarifa),
        'tipo': oferta.tipo,
        'estado': oferta.estado,
    }


def _payload_viaje(viaje):
    return {
        'id': str(viaje.id),
        'solicitudId': str(viaje.solicitud_id),
        'pasajeroId': str(viaje.pasajero_id),
        'conductorId': str(viaje.conductor_id),
        'tarifaFinal': float(viaje.tarifa_final),
        'estado': viaje.estado,
    }


class SocketIORealtimeNotifier(RealtimeNotifier):
    """Implementación concreta: traduce eventos de dominio en mensajes
    Socket.IO dirigidos a los canales (rooms) interesados."""

    def notificar_solicitud_creada(self, solicitud):
        # Todos los conductores conectados ven la nueva solicitud (paso 3).
        sio.emit(
            RealtimeEvents.SOLICITUD_CREADA,
            _payload_solicitud(solicitud),
            room=room_conductores(),
        )

    def notificar_oferta_creada(self, oferta):
        # El pasajero, suscrito al canal de su solicitud, ve la oferta (paso 5).
        sio.emit(
            RealtimeEvents.OFERTA_CREADA,
            _payload_oferta(oferta),
            room=room_solicitud(oferta.solicitud_id),
        )

    def notificar_contraoferta_creada(self, oferta):
        sio.emit(
            RealtimeEvents.CONTRAOFERTA_CREADA,
            _payload_oferta(oferta),
            room=room_solicitud(oferta.solicitud_id),
        )

    def notificar_oferta_aceptada(self, oferta):
        # Avisa al conductor ganador que el pasajero lo seleccionó.
        sio.emit(
            RealtimeEvents.OFERTA_ACEPTADA,
            _payload_oferta(oferta),
            room=room_usuario(oferta.conductor_id),
        )

    def notificar_viaje_asignado(self, viaje):
        # Avisa tanto al pasajero como al conductor (paso 7).
        payload = _payload_viaje(viaje)
        sio.emit(
            RealtimeEvents.VIAJE_ASIGNADO, payload, room=room_usuario(viaje.pasajero_id),
        )
        sio.emit(
            RealtimeEvents.VIAJE_ASIGNADO, payload, room=room_usuario(viaje.conductor_id),
        )
