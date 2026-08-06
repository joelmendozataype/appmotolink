class AppRoutes {
  AppRoutes._();

  // Autenticación
  static const splash = '/splash';
  static const splashName = 'splash';

  static const roleSelection = '/role-selection';
  static const roleSelectionName = 'roleSelection';

  static const recuperarContrasena = '/recuperar-contrasena';
  static const recuperarContrasenaName = 'recuperarContrasena';

  static const login = '/login/:rol';
  static const loginName = 'login';
  static String loginPath(String rol) => '/login/$rol';

  static const registroPasajero = '/registro-pasajero';
  static const registroPasajeroName = 'registroPasajero';

  static const registroMototaxista = '/registro-mototaxista';
  static const registroMototaxistaName = 'registroMototaxista';

  // Pasajero
  static const inicioPasajero = '/passenger/home';
  static const inicioPasajeroName = 'inicioPasajero';

  static const crearSolicitud = '/passenger/crear-solicitud';
  static const crearSolicitudName = 'crearSolicitud';

  static const proponerTarifa = '/passenger/proponer-tarifa';
  static const proponerTarifaName = 'proponerTarifa';

  static const ofertasRecibidas = '/passenger/ofertas/:solicitudId';
  static const ofertasRecibidasName = 'ofertasRecibidas';
  static String ofertasRecibidasPath(String solicitudId) =>
      '/passenger/ofertas/$solicitudId';

  static const conductorSeleccionado = '/passenger/conductor-seleccionado';
  static const conductorSeleccionadoName = 'conductorSeleccionado';

  static const viajeEnCurso = '/passenger/viaje-en-curso/:viajeId';
  static const viajeEnCursoName = 'viajeEnCurso';
  static String viajeEnCursoPath(String viajeId) =>
      '/passenger/viaje-en-curso/$viajeId';

  static const calificacion = '/passenger/calificacion/:viajeId';
  static const calificacionName = 'calificacion';
  static String calificacionPath(String viajeId) =>
      '/passenger/calificacion/$viajeId';

  static const historialPasajero = '/passenger/historial';
  static const historialPasajeroName = 'historialPasajero';

  // Mototaxista
  static const inicioMototaxista = '/driver/home';
  static const inicioMototaxistaName = 'inicioMototaxista';

  static const solicitudesDisponibles = '/driver/solicitudes';
  static const solicitudesDisponiblesName = 'solicitudesDisponibles';

  static const contraoferta = '/driver/contraoferta/:solicitudId';
  static const contraofertaName = 'contraoferta';
  static String contraofertaPath(String solicitudId) =>
      '/driver/contraoferta/$solicitudId';

  static const viajeAsignado = '/driver/viaje-asignado/:viajeId';
  static const viajeAsignadoName = 'viajeAsignado';
  static String viajeAsignadoPath(String viajeId) =>
      '/driver/viaje-asignado/$viajeId';

  static const historialMototaxista = '/driver/historial';
  static const historialMototaxistaName = 'historialMototaxista';

  // Administrador
  static const dashboardAdmin = '/admin/dashboard';
  static const dashboardAdminName = 'dashboardAdmin';

  static const gestionUsuarios = '/admin/usuarios';
  static const gestionUsuariosName = 'gestionUsuarios';

  static const listaConductores = '/admin/conductores';
  static const listaConductoresName = 'listaConductores';

  static const listaPasajeros = '/admin/pasajeros';
  static const listaPasajerosName = 'listaPasajeros';
}
