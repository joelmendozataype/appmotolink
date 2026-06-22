import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/negotiation/domain/repositories/oferta_repository.dart';

class ObtenerOfertas {
  final OfertaRepository repository;

  ObtenerOfertas(this.repository);

  Future<List<Oferta>> call(String solicitudId) {
    return repository.obtenerOfertas(solicitudId);
  }
}
