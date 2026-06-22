import 'package:mobile/features/profile/data/datasources/mototaxista_remote_datasource.dart';
import 'package:mobile/features/profile/data/models/mototaxista_model.dart';
import 'package:mobile/features/profile/domain/entities/mototaxista_entity.dart';
import 'package:mobile/features/profile/domain/repositories/mototaxista_repository.dart';

class MototaxistaRepositoryImpl implements MototaxistaRepository {
  final MototaxistaRemoteDataSource remoteDataSource;

  MototaxistaRepositoryImpl(this.remoteDataSource);

  MototaxistaModel _toModel(Mototaxista mototaxista) => MototaxistaModel(
        usuario: mototaxista.usuario,
        licencia: mototaxista.licencia,
        placa: mototaxista.placa,
        marcaVehiculo: mototaxista.marcaVehiculo,
        modeloVehiculo: mototaxista.modeloVehiculo,
      );

  @override
  Future<Mototaxista> obtenerPerfil(String usuarioId) {
    return remoteDataSource.obtenerPerfil(usuarioId);
  }

  @override
  Future<Mototaxista> registrarPerfil(Mototaxista mototaxista) {
    return remoteDataSource.registrarPerfil(_toModel(mototaxista));
  }

  @override
  Future<Mototaxista> actualizarPerfil(Mototaxista mototaxista) {
    return remoteDataSource.actualizarPerfil(_toModel(mototaxista));
  }

  @override
  Future<List<Mototaxista>> listarTodos() {
    return remoteDataSource.listarTodos();
  }
}
