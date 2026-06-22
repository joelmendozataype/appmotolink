class SocketEvents {
  SocketEvents._();

  static const solicitudCreada = 'SolicitudCreada';
  static const ofertaCreada = 'OfertaCreada';
  static const contraOfertaCreada = 'ContraOfertaCreada';
  static const ofertaAceptada = 'OfertaAceptada';
  static const viajeAsignado = 'ViajeAsignado';
}

class SocketRooms {
  SocketRooms._();

  static const conductores = 'conductores';

  static String solicitud(String solicitudId) => 'solicitud_$solicitudId';

  static String usuario(String usuarioId) => 'usuario_$usuarioId';
}
