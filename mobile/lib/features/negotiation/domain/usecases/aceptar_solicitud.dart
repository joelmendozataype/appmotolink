import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/negotiation/domain/repositories/oferta_repository.dart';

class AceptarSolicitud {
  final OfertaRepository repository;

  AceptarSolicitud(this.repository);

  Future<Oferta> call(String solicitudId, String conductorId) {
    return repository.aceptarSolicitud(solicitudId, conductorId);
  }
}
