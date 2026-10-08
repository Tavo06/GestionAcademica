/// Compares a workday's real clock-in/out with the class schedule.
library;

enum Puntualidad { anticipada, puntual, tarde, incidencia }

/// Arriving up to this many minutes early still counts as on time.
const int toleranciaAnticipadaMinutos = 5;

/// Clock-in is allowed from this many minutes before the class starts.
const int aperturaEntradaMinutos = 60;

class ResultadoMarca {
  final Puntualidad tipo;

  /// Real minus scheduled time, in whole minutes (positive = later).
  final int minutos;

  const ResultadoMarca(this.tipo, this.minutos);

  /// "+2 min", "-3 min" or "0 min".
  String get diferencia => minutos > 0 ? '+$minutos min' : '$minutos min';

  String get etiqueta {
    switch (tipo) {
      case Puntualidad.anticipada:
        return 'Anticipada';
      case Puntualidad.puntual:
        return 'Puntual';
      case Puntualidad.tarde:
        return 'Tarde: $minutos min';
      case Puntualidad.incidencia:
        return 'Salida anticipada';
    }
  }
}

int _diferenciaMinutos(DateTime programada, DateTime real) =>
    real.difference(programada).inMinutes;

/// Why the teacher can't clock in for a session now, or null if they can:
/// only on the session's day, from [aperturaEntradaMinutos] before it
/// starts until it ends.
String? validarEntrada({
  required DateTime inicio,
  required DateTime fin,
  required DateTime ahora,
}) {
  final mismoDia =
      inicio.year == ahora.year && inicio.month == ahora.month && inicio.day == ahora.day;
  if (!mismoDia) return 'Solo puedes registrar la entrada el día de la sesión.';
  final apertura = inicio.subtract(const Duration(minutes: aperturaEntradaMinutos));
  if (ahora.isBefore(apertura)) {
    final h = apertura.hour.toString().padLeft(2, '0');
    final m = apertura.minute.toString().padLeft(2, '0');
    return 'Podrás registrar tu entrada desde las $h:$m.';
  }
  if (!ahora.isBefore(fin)) return 'La clase ya terminó; no se puede registrar la entrada.';
  return null;
}

ResultadoMarca evaluarEntrada(DateTime programada, DateTime real) {
  final minutos = _diferenciaMinutos(programada, real);
  if (minutos > 0) return ResultadoMarca(Puntualidad.tarde, minutos);
  if (minutos < -toleranciaAnticipadaMinutos) {
    return ResultadoMarca(Puntualidad.anticipada, minutos);
  }
  return ResultadoMarca(Puntualidad.puntual, minutos);
}

/// Leaving before the class ends is an incident; on time or later is fine.
ResultadoMarca evaluarSalida(DateTime programada, DateTime real) {
  final minutos = _diferenciaMinutos(programada, real);
  if (minutos < 0) return ResultadoMarca(Puntualidad.incidencia, minutos);
  return ResultadoMarca(Puntualidad.puntual, minutos);
}
