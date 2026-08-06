class RealtimeEvents:
    SOLICITUD_CREADA = 'SolicitudCreada'
    OFERTA_CREADA = 'OfertaCreada'
    CONTRAOFERTA_CREADA = 'ContraOfertaCreada'
    OFERTA_ACEPTADA = 'OfertaAceptada'
    VIAJE_ASIGNADO = 'ViajeAsignado'
    SOLICITUD_CANCELADA = 'SolicitudCancelada'
    VIAJE_CANCELADO = 'ViajeCancelado'


def room_conductores():
    return 'conductores'


def room_solicitud(solicitud_id):
    return f'solicitud_{solicitud_id}'


def room_usuario(usuario_id):
    return f'usuario_{usuario_id}'
