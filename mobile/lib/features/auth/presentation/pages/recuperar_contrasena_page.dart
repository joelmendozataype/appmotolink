import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:mobile/core/di/service_locator.dart';
import 'package:mobile/core/error/exceptions.dart';
import 'package:mobile/core/utils/validaciones.dart';
import 'package:mobile/shared/widgets/cabecera_curva.dart';
import 'package:mobile/shared/widgets/campo_contrasena.dart';

/// Recuperación de contraseña en dos pasos, dentro de la misma pantalla.
///
/// Se pide el correo, llega un código de 6 dígitos y se escribe junto a la
/// contraseña nueva. Se usa un código y no un enlace porque la app no
/// tiene enlaces profundos: teclear seis números es más simple que salir
/// al correo, pulsar un enlace y volver.
class RecuperarContrasenaPage extends StatefulWidget {
  const RecuperarContrasenaPage({super.key});

  @override
  State<RecuperarContrasenaPage> createState() =>
      _RecuperarContrasenaPageState();
}

class _RecuperarContrasenaPageState extends State<RecuperarContrasenaPage> {
  final _formKey = GlobalKey<FormState>();
  final _correoController = TextEditingController();
  final _codigoController = TextEditingController();
  final _contrasenaController = TextEditingController();

  bool _codigoEnviado = false;
  bool _cargando = false;

  @override
  void dispose() {
    _correoController.dispose();
    _codigoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _pedirCodigo() async {
    if (_correoController.text.trim().isEmpty) {
      _avisar('Escribe tu correo');
      return;
    }
    setState(() => _cargando = true);
    try {
      await ServiceLocator.pedirCodigoRecuperacion(
        _correoController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _codigoEnviado = true);
      // El mensaje es el mismo exista o no la cuenta: el backend no
      // revela quién está registrado, y la app tampoco debe hacerlo.
      _avisar('Si el correo está registrado, recibirás un código.');
    } catch (e) {
      _avisar(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  Future<void> _restablecer() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _cargando = true);
    try {
      await ServiceLocator.restablecerContrasena(
        _correoController.text.trim(),
        _codigoController.text.trim(),
        _contrasenaController.text,
      );
      if (!mounted) return;
      _avisar('Contraseña actualizada. Ya puedes iniciar sesión.');
      context.pop();
    } catch (e) {
      _avisar(mensajeDeError(e));
    } finally {
      if (mounted) setState(() => _cargando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colores = Theme.of(context).colorScheme;
    return Scaffold(
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Stack(
              children: [
                CabeceraCurva(
                  altura: 200,
                  child: Padding(
                    padding: const EdgeInsets.fromLTRB(24, 60, 24, 0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(Icons.lock_reset,
                            size: 44, color: Colors.white),
                        const SizedBox(height: 12),
                        Text(
                          'Recuperar contraseña',
                          style: Theme.of(context)
                              .textTheme
                              .headlineSmall
                              ?.copyWith(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                              ),
                        ),
                      ],
                    ),
                  ),
                ),
                Positioned(
                  top: MediaQuery.of(context).padding.top + 4,
                  left: 4,
                  child: IconButton(
                    icon: const Icon(Icons.arrow_back, color: Colors.white),
                    tooltip: 'Volver',
                    onPressed: () => context.pop(),
                  ),
                ),
              ],
            ),
            Padding(
              padding: const EdgeInsets.all(24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 420),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          _codigoEnviado
                              ? 'Revisa tu correo y escribe el código de 6 '
                                  'dígitos junto a tu contraseña nueva.'
                              : 'Escribe el correo de tu cuenta y te '
                                  'enviaremos un código.',
                          style: TextStyle(color: colores.onSurfaceVariant),
                        ),
                        const SizedBox(height: 20),
                        TextFormField(
                          controller: _correoController,
                          keyboardType: TextInputType.emailAddress,
                          // Bloqueado tras enviar: cambiarlo aquí dejaría
                          // el código apuntando a otra cuenta.
                          enabled: !_codigoEnviado,
                          decoration: const InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: Icon(Icons.mail_outline),
                          ),
                        ),
                        if (_codigoEnviado) ...[
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _codigoController,
                            keyboardType: TextInputType.number,
                            maxLength: 6,
                            decoration: const InputDecoration(
                              labelText: 'Código de 6 dígitos',
                              prefixIcon: Icon(Icons.pin),
                              counterText: '',
                            ),
                            validator: (v) => (v == null || v.trim().length != 6)
                                ? 'El código tiene 6 dígitos'
                                : null,
                          ),
                          const SizedBox(height: 8),
                          CampoContrasena(
                            controller: _contrasenaController,
                            etiqueta: 'Contraseña nueva',
                            esRegistro: true,
                            ayuda: 'Mínimo 8 caracteres. Evita las comunes.',
                            iconoInicial: Icons.lock_outline,
                            validator: Validaciones.contrasena,
                          ),
                        ],
                        const SizedBox(height: 24),
                        SizedBox(
                          height: 50,
                          child: FilledButton(
                            onPressed: _cargando
                                ? null
                                : (_codigoEnviado ? _restablecer : _pedirCodigo),
                            child: _cargando
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                    ),
                                  )
                                : Text(
                                    _codigoEnviado
                                        ? 'Cambiar contraseña'
                                        : 'Enviarme el código',
                                  ),
                          ),
                        ),
                        if (_codigoEnviado) ...[
                          const SizedBox(height: 8),
                          TextButton(
                            onPressed: _cargando
                                ? null
                                : () => setState(() => _codigoEnviado = false),
                            child: const Text('Usar otro correo'),
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
