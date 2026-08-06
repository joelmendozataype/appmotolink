import 'package:flutter/material.dart';

/// Banner que avisa de que hay un viaje en curso y lleva a él.
///
/// Existe porque depender solo del aviso en vivo era frágil: si el
/// usuario tenía la app cerrada, sin red, o simplemente no llegó el
/// evento, se quedaba en la pantalla de inicio sin forma de volver a su
/// propio viaje. Preguntar al abrir cubre ese hueco.
class AvisoViajeActivo extends StatelessWidget {
  final String titulo;
  final String detalle;
  final VoidCallback onEntrar;

  const AvisoViajeActivo({
    super.key,
    required this.titulo,
    required this.detalle,
    required this.onEntrar,
  });

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Card(
      margin: const EdgeInsets.fromLTRB(16, 12, 16, 0),
      color: colores.primaryContainer,
      child: InkWell(
        onTap: onEntrar,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Icon(Icons.navigation, color: colores.onPrimaryContainer),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colores.onPrimaryContainer,
                      ),
                    ),
                    Text(
                      detalle,
                      style: TextStyle(color: colores.onPrimaryContainer),
                    ),
                  ],
                ),
              ),
              Icon(Icons.chevron_right, color: colores.onPrimaryContainer),
            ],
          ),
        ),
      ),
    );
  }
}
