import 'package:mobile/core/enums/estado_viaje.dart';
import 'package:mobile/features/trip_tracking/data/datasources/viaje_remote_datasource.dart';
import 'package:mobile/features/trip_tracking/domain/entities/viaje_entity.dart';
import 'package:mobile/features/trip_tracking/domain/repositories/viaje_repository.dart';

class ViajeRepositoryImpl implements ViajeRepository {
  final ViajeRemoteDataSource remoteDataSource;

  ViajeRepositoryImpl(this.remoteDataSource);

  @override
  Future<Viaje> obtenerPorId(String viajeId) {
    return remoteDataSource.obtenerPorId(viajeId);
  }

  @override
  Future<Viaje> obtenerViajeActivo(String usuarioId) {
    return remoteDataSource.obtenerViajeActivo(usuarioId);
  }

  @override
  Future<Viaje> actualizarEstado(String viajeId, EstadoViaje estado) {
    return remoteDataSource.actualizarEstado(viajeId, estado);
  }

  @override
  Future<Viaje> finalizarViaje(String viajeId) {
    return remoteDataSource.finalizarViaje(viajeId);
  }

  @override
  Future<List<Viaje>> listarTodos() {
    return remoteDataSource.listarTodos();
  }
}
