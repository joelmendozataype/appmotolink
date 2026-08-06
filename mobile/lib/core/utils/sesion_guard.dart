import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/routing/app_routes.dart';
import 'package:mobile/features/auth/domain/entities/usuario_entity.dart';
import 'package:mobile/features/auth/presentation/providers/auth_provider.dart';
import 'package:provider/provider.dart';

/// Devuelve el usuario en sesión, o `null` si ya no hay ninguna.
///
/// [AuthProvider] guarda la sesión solo en memoria, así que se pierde al
/// recargar el navegador o tras un hot restart. go_router, en cambio,
/// restaura la ruta desde la URL: se puede acabar en una pantalla que da
/// por hecho que hay usuario cuando ya no lo hay.
///
/// Antes esas pantallas hacían `usuarioActual!`, y el `!` reventaba con
/// "Unexpected null value" fuera de cualquier try: el botón se quedaba
/// mudo, sin error visible. Con este helper se avisa y se vuelve a la
/// selección de rol.
Usuario? usuarioEnSesion(BuildContext context) {
  final usuario = context.read<AuthProvider>().usuarioActual;
  if (usuario != null) return usuario;

  ScaffoldMessenger.of(context).showSnackBar(
    const SnackBar(
      content: Text('Tu sesión terminó. Vuelve a iniciar sesión.'),
    ),
  );
  context.go(AppRoutes.roleSelection);
  return null;
}
