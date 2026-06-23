import 'package:flutter/material.dart';
import 'package:mobile/shared/widgets/error_retry_view.dart';

/// Spinner centrado para el estado "cargando".
class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) =>
      const Center(child: CircularProgressIndicator());
}

/// Mensaje centrado para el estado "sin datos" (lista vacía tras cargar).
class EmptyView extends StatelessWidget {
  final String mensaje;

  const EmptyView({super.key, required this.mensaje});

  @override
  Widget build(BuildContext context) => Center(child: Text(mensaje));
}

/// Elige automáticamente entre cargando / error / vacío / datos para una
/// pantalla que carga algo del backend, reusando [LoadingView], [EmptyView]
/// y [ErrorRetryView] en vez de repetir la misma cascada de `if` en cada
/// página (ofertas recibidas, solicitudes disponibles, historial, gestión
/// de usuarios, etc.).
class AsyncStateView<T> extends StatelessWidget {
  final bool cargando;
  final String? error;
  final T datos;
  final bool Function(T datos) estaVacio;
  final VoidCallback onReintentar;
  final String mensajeVacio;
  final Widget Function(T datos) builder;

  const AsyncStateView({
    super.key,
    required this.cargando,
    required this.error,
    required this.datos,
    required this.estaVacio,
    required this.onReintentar,
    required this.mensajeVacio,
    required this.builder,
  });

  @override
  Widget build(BuildContext context) {
    if (error != null) {
      return ErrorRetryView(mensaje: error!, onRetry: onReintentar);
    }
    if (cargando) {
      return const LoadingView();
    }
    if (estaVacio(datos)) {
      return EmptyView(mensaje: mensajeVacio);
    }
    return builder(datos);
  }
}
