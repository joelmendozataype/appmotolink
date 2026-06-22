import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';

abstract class OfertaRepository {
  Future<Oferta> aceptarSolicitud(String solicitudId, String conductorId);

  Future<Oferta> contraofertarSolicitud(
    String solicitudId,
    String conductorId,
    double tarifa,
  );

  Future<Oferta> rechazarSolicitud(String solicitudId, String conductorId);

  Future<List<Oferta>> obtenerOfertas(String solicitudId);

  Future<Viaje> seleccionarOferta(String ofertaId);
}
