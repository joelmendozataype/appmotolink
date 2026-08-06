import 'package:flutter/material.dart';

/// Campo de contraseña con botón para mostrarla u ocultarla.
///
/// Escribir a ciegas en un teclado táctil provoca errores, y el usuario
/// solo descubre la errata cuando el login ya ha fallado. Poder revelar
/// lo escrito reduce esos intentos fallidos —que además ahora cuentan
/// para el límite de fuerza bruta— sin sacrificar nada: el texto arranca
/// oculto y solo se revela si la persona lo pide.
class CampoContrasena extends StatefulWidget {
  final TextEditingController controller;
  final String etiqueta;
  final String? Function(String?)? validator;

  /// Ayuda bajo el campo. Útil en el registro, donde el backend exige un
  /// mínimo de 8 caracteres y rechaza las contraseñas comunes.
  final String? ayuda;

  /// En el registro conviene sugerir una contraseña nueva al gestor de
  /// claves; en el login, una ya guardada.
  final bool esRegistro;

  /// Icono a la izquierda. Opcional: solo lo usan las pantallas de acceso.
  final IconData? iconoInicial;

  /// Texto de marca de agua dentro del campo.
  final String? pista;

  const CampoContrasena({
    super.key,
    required this.controller,
    this.etiqueta = 'Contraseña',
    this.validator,
    this.ayuda,
    this.esRegistro = false,
    this.iconoInicial,
    this.pista,
  });

  @override
  State<CampoContrasena> createState() => _CampoContrasenaState();
}

class _CampoContrasenaState extends State<CampoContrasena> {
  bool _oculta = true;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: widget.controller,
      obscureText: _oculta,
      autofillHints: [
        widget.esRegistro ? AutofillHints.newPassword : AutofillHints.password,
      ],
      decoration: InputDecoration(
        labelText: widget.etiqueta,
        hintText: widget.pista,
        prefixIcon:
            widget.iconoInicial == null ? null : Icon(widget.iconoInicial),
        helperText: widget.ayuda,
        helperMaxLines: 2,
        suffixIcon: IconButton(
          icon: Icon(_oculta ? Icons.visibility_off : Icons.visibility),
          // Sin esto, quien use lector de pantalla no sabría qué hace el
          // botón ni en qué estado está el campo.
          tooltip: _oculta ? 'Mostrar contraseña' : 'Ocultar contraseña',
          onPressed: () => setState(() => _oculta = !_oculta),
        ),
      ),
      validator: widget.validator,
    );
  }
}
