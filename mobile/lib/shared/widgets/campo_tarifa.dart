import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:mobile/core/utils/validaciones.dart';

/// Campo para escribir un importe en soles.
///
/// Lo usan las dos pantallas donde se teclea dinero: la del pasajero que
/// propone su tarifa y la del conductor que contraoferta. Estaba
/// duplicado en ambas, cada una con su validación, y con el icono del
/// dólar pese a que aquí se paga en soles.
///
/// El filtro de escritura es lo que de verdad evita el problema: en vez
/// de dejar teclear cualquier cosa y avisar después, sencillamente no
/// admite lo que no sea un importe. Así no hay forma de escribir letras,
/// un signo menos ni tres decimales.
class CampoTarifa extends StatelessWidget {
  final TextEditingController controller;

  /// Texto de la etiqueta. Cambia según quién lo use.
  final String etiqueta;

  const CampoTarifa({
    super.key,
    required this.controller,
    required this.etiqueta,
  });

  /// Hasta cuatro cifras enteras y como mucho dos decimales.
  static final _formato = RegExp(r'^\d{0,4}([.]\d{0,2})?$');

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        TextInputFormatter.withFunction((anterior, nuevo) {
          if (nuevo.text.isEmpty) return nuevo;
          // Se rechaza la pulsación entera si dejaría el campo con algo
          // que no es un importe: el usuario ve que no pasa nada, en vez
          // de escribir y encontrarse un error al enviar.
          return _formato.hasMatch(nuevo.text) ? nuevo : anterior;
        }),
      ],
      decoration: InputDecoration(
        labelText: etiqueta,
        // Soles, no dólares. Se usa texto y no un icono porque no existe
        // un icono de sol en el juego de Material.
        prefixText: 'S/  ',
        prefixStyle: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        ),
        hintText: '0.00',
      ),
      validator: Validaciones.tarifa,
    );
  }
}
