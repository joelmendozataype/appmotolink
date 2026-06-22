import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/negotiation/domain/repositories/oferta_repository.dart';

class RechazarSolicitud {
  final OfertaRepository repository;

  RechazarSolicitud(this.repository);

  Future<Oferta> call(String solicitudId, String conductorId) {
    return repository.rechazarSolicitud(solicitudId, conductorId);
  }
}
