/// Formato de fechas y duraciones para el historial.
///
/// Se escribe a mano en vez de usar `intl` para no añadir una dependencia
/// y su carga de localizaciones por dos formatos: la app es solo en
/// español y solo necesita estos casos.
class FormatoFecha {
  static const _meses = [
    'ene', 'feb', 'mar', 'abr', 'may', 'jun',
    'jul', 'ago', 'sep', 'oct', 'nov', 'dic',
  ];

  /// Fecha legible y relativa según lo reciente que sea:
  /// "Hoy 14:30", "Ayer 09:05", "3 ago 18:42", "12 dic 2025".
  ///
  /// Los viajes migrados desde la base anterior no tienen fecha, de ahí
  /// que acepte null y devuelva un texto honesto en vez de inventarla.
  static String legible(DateTime? fecha) {
    if (fecha == null) return 'Fecha no registrada';

    final ahora = DateTime.now();
    final dia = DateTime(fecha.year, fecha.month, fecha.day);
    final hoy = DateTime(ahora.year, ahora.month, ahora.day);
    final diferencia = hoy.difference(dia).inDays;
    final hora = '${_dos(fecha.hour)}:${_dos(fecha.minute)}';

    if (diferencia == 0) return 'Hoy $hora';
    if (diferencia == 1) return 'Ayer $hora';
    if (fecha.year != ahora.year) {
      return '${fecha.day} ${_meses[fecha.month - 1]} ${fecha.year}';
    }
    return '${fecha.day} ${_meses[fecha.month - 1]} $hora';
  }

  /// Duración en palabras: "8 min", "1 h 25 min".
  /// Devuelve null si no se puede calcular, para que quien llame decida
  /// qué mostrar en su lugar.
  static String? duracion(int? minutos) {
    if (minutos == null || minutos < 0) return null;
    if (minutos < 60) return '$minutos min';
    final horas = minutos ~/ 60;
    final resto = minutos % 60;
    return resto == 0 ? '$horas h' : '$horas h $resto min';
  }

  static String _dos(int n) => n.toString().padLeft(2, '0');
}
