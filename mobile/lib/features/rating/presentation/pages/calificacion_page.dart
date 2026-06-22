import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/routing/app_routes.dart';

class CalificacionPage extends StatefulWidget {
  final String viajeId;

  const CalificacionPage({super.key, required this.viajeId});

  @override
  State<CalificacionPage> createState() => _CalificacionPageState();
}

class _CalificacionPageState extends State<CalificacionPage> {
  int _estrellas = 5;
  final _comentarioController = TextEditingController();
  bool _enviando = false;

  Future<void> _enviar() async {
    setState(() => _enviando = true);
    try {
      await ServiceLocator.enviarCalificacion(
        widget.viajeId,
        _estrellas,
        _comentarioController.text.trim(),
      );
      if (!mounted) return;
      context.go(AppRoutes.inicioPasajero);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text(mensajeDeError(e))));
    } finally {
      if (mounted) setState(() => _enviando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Califica tu viaje')),
      body: Padding(
        padding: const EdgeInsets.all(24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  '¿Cómo fue tu experiencia?',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(5, (i) {
                    final valor = i + 1;
                    return IconButton(
                      icon: Icon(
                        valor <= _estrellas ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                        size: 36,
                      ),
                      onPressed: () => setState(() => _estrellas = valor),
                    );
                  }),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _comentarioController,
                  decoration: const InputDecoration(
                    labelText: 'Comentario (opcional)',
                  ),
                  maxLines: 3,
                ),
                const SizedBox(height: 24),
                FilledButton(
                  onPressed: _enviando ? null : _enviar,
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    child: _enviando
                        ? const SizedBox(
                            height: 18,
                            width: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Text('Enviar calificación'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
