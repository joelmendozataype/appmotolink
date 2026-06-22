import 'package:flutter/material.dart';

/// Estado de error mostrado cuando una carga inicial falla, con botón para
/// reintentar. Reemplaza dejar el spinner girando para siempre cuando la
/// petición lanza una excepción no capturada.
class ErrorRetryView extends StatelessWidget {
  final String mensaje;
  final VoidCallback onRetry;

  const ErrorRetryView({super.key, required this.mensaje, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.error_outline, size: 48, color: Colors.grey),
            const SizedBox(height: 12),
            Text(mensaje, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Reintentar'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
