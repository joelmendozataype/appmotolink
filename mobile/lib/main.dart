import 'package:flutter/material.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/push/push_service.dart';
import 'package:mobile/core/realtime/escucha_global.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Firebase se inicia antes de la app, pero sin bloquearla: si falla
  // —sin Play Services, o sin configuración válida— la app arranca igual
  // y simplemente no habrá notificaciones.
  await PushService.instance.iniciar();

  // Conexión en segundo plano: si el backend no está disponible, el
  // cliente Socket.IO sigue reintentando solo (reconexión automática)
  // sin bloquear ni romper la app.
  SocketService.instance.connect(ApiConstants.socketUrl);
  runApp(const MotolinkApp());
}

class MotolinkApp extends StatefulWidget {
  const MotolinkApp({super.key});

  @override
  State<MotolinkApp> createState() => _MotolinkAppState();
}

class _MotolinkAppState extends State<MotolinkApp> {
  // Se crea aquí y no dentro del provider para poder pasárselo a la
  // escucha global, que vive por encima del árbol de widgets.
  final AuthProvider _auth = AuthProvider();

  @override
  void initState() {
    super.initState();
    // Los avisos de viaje asignado no pertenecen a ninguna pantalla: le
    // pueden llegar al conductor esté donde esté. Antes solo los oía la
    // pantalla de inicio, así que desde cualquier otra se perdían.
    EscuchaGlobal.instance.activar(_auth);
  }

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider.value(
      value: _auth,
      child: MaterialApp.router(
        title: 'MOTOLINK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
        // Permite mostrar avisos desde la escucha global, que no tiene un
        // BuildContext de pantalla.
        scaffoldMessengerKey: EscuchaGlobal.mensajeria,
      ),
    );
  }
}
