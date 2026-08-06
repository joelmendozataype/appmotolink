class RealtimeEvents:
    SOLICITUD_CREADA = 'SolicitudCreada'
    OFERTA_CREADA = 'OfertaCreada'
    CONTRAOFERTA_CREADA = 'ContraOfertaCreada'
    OFERTA_ACEPTADA = 'OfertaAceptada'
    VIAJE_ASIGNADO = 'ViajeAsignado'
    SOLICITUD_CANCELADA = 'SolicitudCancelada'
    VIAJE_CANCELADO = 'ViajeCancelado'
    VIAJE_FINALIZADO = 'ViajeFinalizado'
    UBICACION_ACTUALIZADA = 'UbicacionActualizada'


def room_conductores():
    return 'conductores'


def room_solicitud(solicitud_id):
    return f'solicitud_{solicitud_id}'


def room_viaje(viaje_id):
    """Sala del viaje: solo sus dos participantes se suscriben, y es por
    donde se intercambian las posiciones en vivo."""
    return f'viaje_{viaje_id}'


def room_usuario(usuario_id):
    return f'usuario_{usuario_id}'
