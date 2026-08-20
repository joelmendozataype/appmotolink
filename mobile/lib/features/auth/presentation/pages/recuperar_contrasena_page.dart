import 'dart:async';

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

  /// En qué punto está la comprobación del correo contra el servidor.
  _EstadoCorreo _estadoCorreo = _EstadoCorreo.vacio;
  Timer? _esperaTecleo;

  /// El último correo consultado, para no repetir la petición mientras el
  /// usuario no cambie nada.
  String _ultimoConsultado = '';

  @override
  void initState() {
    super.initState();
    _correoController.addListener(_alEscribirCorreo);
  }

  @override
  void dispose() {
    _esperaTecleo?.cancel();
    _correoController.removeListener(_alEscribirCorreo);
    _correoController.dispose();
    _codigoController.dispose();
    _contrasenaController.dispose();
    super.dispose();
  }

  /// Consulta al servidor si el correo existe, pero solo cuando el usuario
  /// deja de teclear: sin esta espera se lanzaría una petición por cada
  /// letra.
  void _alEscribirCorreo() {
    _esperaTecleo?.cancel();
    final correo = _correoController.text.trim();

    if (Validaciones.correo(correo) != null) {
      // Ni siquiera tiene forma de correo: no hay nada que preguntar.
      _ultimoConsultado = '';
      _cambiarEstado(
        correo.isEmpty ? _EstadoCorreo.vacio : _EstadoCorreo.formatoInvalido,
      );
      return;
    }
    if (correo == _ultimoConsultado) return;

    _cambiarEstado(_EstadoCorreo.comprobando);
    _esperaTecleo = Timer(
      const Duration(milliseconds: 600),
      () => _comprobarCorreo(correo),
    );
  }

  Future<void> _comprobarCorreo(String correo) async {
    try {
      final registrado = await ServiceLocator.correoRegistrado(correo);
      // Si mientras tanto siguió escribiendo, esta respuesta ya no vale.
      if (!mounted || _correoController.text.trim() != correo) return;
      _ultimoConsultado = correo;
      _cambiarEstado(
        registrado ? _EstadoCorreo.registrado : _EstadoCorreo.noRegistrado,
      );
    } catch (_) {
      // Sin red no se puede saber. Se deja pasar en vez de bloquear el
      // botón: el servidor volverá a comprobarlo al pedir el código.
      if (!mounted || _correoController.text.trim() != correo) return;
      _cambiarEstado(_EstadoCorreo.sinComprobar);
    }
  }

  void _cambiarEstado(_EstadoCorreo estado) {
    if (!mounted || _estadoCorreo == estado) return;
    setState(() => _estadoCorreo = estado);
  }

  /// Si el botón "Enviarme el código" debe estar activo.
  ///
  /// Solo se habilita con una cuenta encontrada. La excepción es
  /// `sinComprobar`: si no hubo red para preguntar, se deja intentar y que
  /// decida el servidor, en vez de dejar al usuario sin salida.
  bool get _puedeContinuar =>
      _codigoEnviado ||
      _estadoCorreo == _EstadoCorreo.registrado ||
      _estadoCorreo == _EstadoCorreo.sinComprobar;

  Widget? _iconoEstado() {
    switch (_estadoCorreo) {
      case _EstadoCorreo.comprobando:
        return const Padding(
          padding: EdgeInsets.all(14),
          child: SizedBox(
            height: 18,
            width: 18,
            child: CircularProgressIndicator(strokeWidth: 2),
          ),
        );
      case _EstadoCorreo.registrado:
        return const Icon(Icons.check_circle, color: Colors.green);
      case _EstadoCorreo.noRegistrado:
        return const Icon(Icons.error_outline, color: Colors.red);
      case _EstadoCorreo.vacio:
      case _EstadoCorreo.formatoInvalido:
      case _EstadoCorreo.sinComprobar:
        return null;
    }
  }

  String? _mensajeEstado() {
    switch (_estadoCorreo) {
      case _EstadoCorreo.formatoInvalido:
        return Validaciones.correo(_correoController.text);
      case _EstadoCorreo.noRegistrado:
        return 'Ese correo no está registrado';
      case _EstadoCorreo.sinComprobar:
        return 'No se pudo comprobar. Puedes intentarlo igual.';
      case _EstadoCorreo.vacio:
      case _EstadoCorreo.comprobando:
      case _EstadoCorreo.registrado:
        return null;
    }
  }

  void _avisar(String texto) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(texto), duration: const Duration(seconds: 5)),
    );
  }

  Future<void> _pedirCodigo() async {
    final problema = Validaciones.correo(_correoController.text);
    if (problema != null) {
      _avisar(problema);
      return;
    }
    setState(() => _cargando = true);
    try {
      await ServiceLocator.pedirCodigoRecuperacion(
        _correoController.text.trim(),
      );
      if (!mounted) return;
      setState(() => _codigoEnviado = true);
      _avisar('Te enviamos un código. Revisa tu correo.');
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
                          decoration: InputDecoration(
                            labelText: 'Correo',
                            prefixIcon: const Icon(Icons.mail_outline),
                            // El resultado de la comprobación, en el
                            // propio campo: es donde el usuario mira.
                            suffixIcon: _codigoEnviado ? null : _iconoEstado(),
                            errorText:
                                _codigoEnviado ? null : _mensajeEstado(),
                            helperText: _estadoCorreo ==
                                    _EstadoCorreo.registrado
                                ? 'Cuenta encontrada'
                                : null,
                            helperStyle: TextStyle(color: colores.primary),
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
                            onPressed: (_cargando || !_puedeContinuar)
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

/// En qué punto está la comprobación del correo contra el servidor.
enum _EstadoCorreo {
  /// Todavía no se ha escrito nada.
  vacio,

  /// No tiene forma de correo, así que no se pregunta al servidor.
  formatoInvalido,

  /// Consulta en curso.
  comprobando,

  /// Tiene cuenta activa: es el único caso que habilita el botón.
  registrado,

  /// No tiene cuenta: no serviría de nada enviar un código.
  noRegistrado,

  /// No hubo red para preguntar. Se deja continuar y decide el servidor.
  sinComprobar,
}
