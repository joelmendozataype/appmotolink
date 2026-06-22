import 'package:mobile/features/negotiation/data/datasources/oferta_remote_datasource.dart';
import 'package:mobile/features/negotiation/domain/entities/oferta_entity.dart';
import 'package:mobile/features/negotiation/domain/repositories/oferta_repository.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';

class OfertaRepositoryImpl implements OfertaRepository {
  final OfertaRemoteDataSource remoteDataSource;

  OfertaRepositoryImpl(this.remoteDataSource);

  @override
  Future<Oferta> aceptarSolicitud(String solicitudId, String conductorId) {
    return remoteDataSource.aceptarSolicitud(solicitudId, conductorId);
  }

  @override
  Future<Oferta> contraofertarSolicitud(
    String solicitudId,
    String conductorId,
    double tarifa,
  ) {
    return remoteDataSource.contraofertarSolicitud(
      solicitudId,
      conductorId,
      tarifa,
    );
  }

  @override
  Future<Oferta> rechazarSolicitud(String solicitudId, String conductorId) {
    return remoteDataSource.rechazarSolicitud(solicitudId, conductorId);
  }

  @override
  Future<List<Oferta>> obtenerOfertas(String solicitudId) {
    return remoteDataSource.obtenerOfertas(solicitudId);
  }

  @override
  Future<Viaje> seleccionarOferta(String ofertaId) {
    return remoteDataSource.seleccionarOferta(ofertaId);
  }
}
