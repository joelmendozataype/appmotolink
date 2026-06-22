import 'package:mobile/features/negotiation/domain/repositories/oferta_repository.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';

class SeleccionarOferta {
  final OfertaRepository repository;

  SeleccionarOferta(this.repository);

  Future<Viaje> call(String ofertaId) {
    return repository.seleccionarOferta(ofertaId);
  }
}
