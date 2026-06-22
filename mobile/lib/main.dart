import 'package:flutter/material.dart';
import 'package:mobile/core/constants/api_constants.dart';
import 'package:mobile/core/realtime/socket_service.dart';
import 'package:mobile/core/routing/app_router.dart';
import 'package:mobile/core/theme/app_theme.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

void main() {
  // Conexión en segundo plano: si el backend no está disponible, el
  // cliente Socket.IO sigue reintentando solo (reconexión automática)
  // sin bloquear ni romper la app.
  SocketService.instance.connect(ApiConstants.socketUrl);
  runApp(const MotolinkApp());
}

class MotolinkApp extends StatelessWidget {
  const MotolinkApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ChangeNotifierProvider(
      create: (_) => AuthProvider(),
      child: MaterialApp.router(
        title: 'MOTOLINK',
        debugShowCheckedModeBanner: false,
        theme: AppTheme.light,
        routerConfig: AppRouter.router,
      ),
    );
  }
}
