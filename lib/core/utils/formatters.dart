/// Formatos de fechas, horas, duraciones, porcentajes y notas usados en
/// toda la app.
library;

import '../logic/horario.dart';

String formatHora(DateTime? fecha) {
  if (fecha == null) return '--:--';
  final hora = fecha.hour.toString().padLeft(2, '0');
  final minuto = fecha.minute.toString().padLeft(2, '0');
  return '$hora:$minuto';
}

String formatFechaCorta(DateTime fecha) {
  final dia = fecha.day.toString().padLeft(2, '0');
  final mes = fecha.month.toString().padLeft(2, '0');
  return '$dia/$mes/${fecha.year}';
}

const _meses = [
  'enero',
  'febrero',
  'marzo',
  'abril',
  'mayo',
  'junio',
  'julio',
  'agosto',
  'septiembre',
  'octubre',
  'noviembre',
  'diciembre',
];

/// "Martes 29 de septiembre" (con el año cuando [conAnio]).
String formatFechaLarga(DateTime fecha, {bool conAnio = false}) {
  final dia = diasSemanaNombres[fecha.weekday]!;
  final texto = '$dia ${fecha.day} de ${_meses[fecha.month - 1]}';
  return conAnio ? '$texto de ${fecha.year}' : texto;
}

String formatDuracion(Duration? duracion) {
  if (duracion == null) return '—';
  final horas = duracion.inHours;
  final minutos = duracion.inMinutes.remainder(60).toString().padLeft(2, '0');
  return '${horas}h ${minutos}min';
}

/// "62.5%", "30%".
String formatPorcentaje(double valor) {
  final redondeado = (valor * 100).round() / 100;
  final texto = redondeado == redondeado.roundToDouble()
      ? redondeado.toStringAsFixed(0)
      : redondeado.toStringAsFixed(2).replaceFirst(RegExp(r'0$'), '');
  return '$texto%';
}

/// Nota vigesimal con dos decimales ("14.50"), o "—" sin nota.
String formatNota(double? nota) => nota == null ? '—' : nota.toStringAsFixed(2);
