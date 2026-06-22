import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/negotiation/domain/repositories/oferta_repository.dart';

class ContraofertarSolicitud {
  final OfertaRepository repository;

  ContraofertarSolicitud(this.repository);

  Future<Oferta> call(String solicitudId, String conductorId, double tarifa) {
    return repository.contraofertarSolicitud(solicitudId, conductorId, tarifa);
  }
}
